//
//  AlbumsTableViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 25/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import Photos

class AlbumsViewController: UITableViewController {
    
    let topLevelUserCollectionsResult = PHAssetCollection.fetchTopLevelUserCollectionsWithOptions(nil)
    var selectedCollection: PHAssetCollection?

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topLevelUserCollectionsResult.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AlbumCellID", forIndexPath: indexPath)

        let collection = topLevelUserCollectionsResult[indexPath.row] as! PHAssetCollection
        cell.textLabel?.text = collection.localizedTitle

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedCollection = topLevelUserCollectionsResult[indexPath.row] as? PHAssetCollection
        performSegueWithIdentifier("ShowPhotos", sender: self)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowPhotos" {
            let photosVC = segue.destinationViewController as! UploadPhotosViewController
            photosVC.collection = selectedCollection
        }
    }

}
