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

class PhotosViewController: UITableViewController {
    
    let imageManager = PHImageManager.defaultManager()
    
    var collection: PHAssetCollection! {
        didSet {
            assetsResult = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
            tableView.reloadData()
        }
    }
    var assetsResult: PHFetchResult? {
        didSet {
            if let result = assetsResult {
                fetchImagesForAssetResult(result)
            }
        }
    }
    
    var uploadRequests = [UploadRequest?]()
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = collection.localizedTitle
    }
    
    // MARK: - PhotosViewController
    
    func fetchImagesForAssetResult(result: PHFetchResult) {
        result.enumerateObjectsUsingBlock({ (obj, index, _) in
            guard let asset = obj as? PHAsset else {
                return
            }
            
            self.imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(40, 40), contentMode: .AspectFit, options: nil) { (image, info) in
                let uploadableImage = UploadableImage(title: asset.title, image: image)
                let request = UploadRequest(image: uploadableImage)
                self.uploadRequests.append(request)
                self.tableView.reloadData()
            }
        })
    }
    
    @IBAction func uploadAllTapped(sender: AnyObject) {
        startNextUpload()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uploadRequests.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let request = uploadRequests[indexPath.row] {
            let cellID = request.state.cellID() ?? UploadState.Waiting.cellID()
            let cell = tableView.dequeueReusableCellWithIdentifier(cellID, forIndexPath: indexPath) as! PhotoUploadCell
            
            cell.photoTitleLabel?.text = request.image.title
            cell.photoImageView?.image = request.image.image
            
            if request.state == .Uploading {
                cell.progressView?.progress = request.progress
            }
            
            return cell
        }
        return tableView.dequeueReusableCellWithIdentifier(PhotoUploadCell.loadingCellID, forIndexPath: indexPath)
    }
}

extension PhotosViewController {
    func startNextUpload() {
        
        let waiting = self.uploadRequests.filter {$0?.state == .Waiting}
        if let first = waiting.first, nextRequest = first {
            
            let index = self.uploadRequests.indexOf({ (uploadRequest) -> Bool in
                guard let request = uploadRequest else {
                    return false
                }
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
}
