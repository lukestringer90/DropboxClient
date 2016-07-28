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
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = collection.localizedTitle
    }
    
    // MARK: - Actions
    
    @IBAction func uploadAllTapped(sender: AnyObject) {
        startNextUpload()
    }
    
    // MARK: - PhotosViewController
    
    func createUploadRequestsForAssetResult(result: PHFetchResult) {
        result.enumerateObjectsUsingBlock({ (obj, _, _) in
            guard let asset = obj as? PHAsset else {
                return
            }
            
            PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: CGSizeMake(40, 40), contentMode: .AspectFit, options: nil) { (image, _) in
                let uploadableImage = UploadableImage(title: asset.title, image: image)
                let request = UploadRequest(image: uploadableImage)
                self.uploadRequests.append(request)
                self.tableView.reloadData()
            }
        })
    }
    
    func startNextUpload() {
        
        let waiting = self.uploadRequests.filter {$0.state == .waiting}
        if let nextRequest = waiting.first {
            
            let index = self.uploadRequests.indexOf({ (request) -> Bool in
                return request === nextRequest
            })
            
            let indexPath = NSIndexPath(forItem: index!, inSection: 0)
            
            nextRequest.progressHandler = { progress in
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? PhotoUploadCell {
                    cell.progressView?.setProgress(progress, animated: true)
                }
            }
            
            nextRequest.completionHandler = { _ in
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                self.startNextUpload()
            }
            
            nextRequest.start()
            // Once started reload tableview so we deque correct cell for the new state
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
        
        cell.photoTitleLabel?.text = request.image.title
        cell.photoImageView?.image = request.image.image
        
        switch request.state {
        case .uploading:
            cell.progressView?.progress = request.progress
        case .uploaded:
            if let response = request.response {
                cell.photoDetailLabel?.text = response.cellDescription()
            }
        default:
            break
        }
        
        return cell
    }
}
