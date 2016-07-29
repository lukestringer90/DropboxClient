//
//  PhotosViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 25/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import Photos
import SwiftyTimer

class UploadPhotosViewController: UITableViewController {
    
    var collection: PHAssetCollection! {
        didSet {
            assetsResult = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
            tableView.reloadData()
        }
    }
    var assetsResult: PHFetchResult? {
        didSet {
            if let result = assetsResult {
                createUploadRequestsForAssetResult(result)
            }
        }
    }
    
    var uploadRequests = [UploadRequest]()
    
    var requestReponsePairs = [RequestResponsePair]()
    
    @IBOutlet weak var uploadLocationButton: UIBarButtonItem!
    @IBOutlet weak var uploadAllButton: UIBarButtonItem!
    
    var folder: Folder? {
        didSet {
            if let name = folder?.name {
                uploadLocationButton.title = "Folder: \(name)"
            }
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = collection.localizedTitle
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true);
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true);
    }
    
    // MARK: - Actions
    
    @IBAction func uploadAllTapped(sender: AnyObject) {
        guard folder != nil else {
            let alert = UIAlertController(title: nil, message: "No Upload Folder selected", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return
        }
        uploadLocationButton.enabled = false
        uploadAllButton.enabled = false
        
        // Restart previosuly failed requests
        var indexPaths = [NSIndexPath]()
        for (index, request) in uploadRequests.enumerate() {
            if request.state == .failed {
                request.state = .waiting
                indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
            }
        }
        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        
        startNextUpload()
    }
    
    @IBAction func dismissToUploadPhotosWithFolder(segue: UIStoryboardSegue) {
        if let folderVC = segue.sourceViewController as? FolderViewController {
            folder = folderVC.folder
        }
    }
    
    @IBAction func dismissToUploadPhotos(segue: UIStoryboardSegue) {
    }
    
    // MARK: - PhotosViewController
    
    func createUploadRequestsForAssetResult(result: PHFetchResult) {
        result.enumerateObjectsUsingBlock({ (obj, _, _) in
            guard let asset = obj as? PHAsset else {
                return
            }
            
            let manager = PHImageManager.defaultManager()
            manager.requestImageForAsset(asset, targetSize: CGSizeMake(40, 40), contentMode: .AspectFit, options: nil) { (fetchedImage, _) in
                
                if let image = fetchedImage, imageManifest = UploadManifest(image: image, title: asset.title) {
                    let request = UploadRequest(manifest: imageManifest)
                    self.uploadRequests.append(request)
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    func startNextUpload() {
        
        let waiting = self.uploadRequests.filter {$0.state == .waiting}
        if let nextRequest = waiting.first, uploadPath = folder?.path {
            
            let index = self.uploadRequests.indexOf({ (request) -> Bool in
                return request === nextRequest
            })
            
            let indexPath = NSIndexPath(forItem: index!, inSection: 0)
            
            nextRequest.progressHandler = { progress in
                dispatch_async(dispatch_get_main_queue(), {
                    if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? PhotoUploadCell {
                        cell.progressView?.setProgress(progress, animated: true)
                    }
                })
            }
            
            nextRequest.completionHandler = { response in
                self.requestReponsePairs.append(RequestResponsePair(request: nextRequest, response: response))
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    self.startNextUpload()
                })
            }
            
            nextRequest.startUploadToPath(uploadPath)
            // Once started reload tableview so we deque correct cell for the new state
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        else {
            uploadLocationButton.enabled = true
            uploadAllButton.enabled = true
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uploadRequests.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let request = uploadRequests[indexPath.row]
        let cellID = PhotoUploadCell.cellIDForState(request.state)
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as! PhotoUploadCell
        
        cell.photoTitleLabel?.text = request.manifest.title
        cell.photoImageView?.image = request.manifest.image
        
        switch request.state {
        case .uploading:
            cell.progressView?.progress = request.progress
        case .uploaded:
            if let response =  self.requestReponsePairs.firstResponseForRequest(request: request) {
                cell.photoDetailLabel?.text = response.cellDescription()
            }
        default:
            break
        }
        
        return cell
    }
}

typealias RequestResponsePair = (request: UploadRequest, response: UploadResponse?)
extension SequenceType where Generator.Element == RequestResponsePair {
    func firstResponseForRequest(request toFind: UploadRequest) -> UploadResponse? {
        return self.filter { (request, response) -> Bool in
            return request === toFind
            }.first?.response
    }
}

extension UploadResponse {
    func cellDescription() -> String {
        let dateFormatter = NSDateFormatter.uploadedDateFormatter()
        return "\(self.fileSize)MB, uploaded \(dateFormatter.stringFromDate(self.uplodDate))"
    }
}
