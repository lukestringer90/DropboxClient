//
//  PhotosViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 25/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import Photos

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
                result.enumerateObjectsUsingBlock({ (obj, index, _) in
                    guard let asset = obj as? PHAsset else {
                        return
                    }
                    
                    self.images.insert(nil, atIndex: index)
                    
                    self.imageManager.requestImageForAsset(asset, targetSize: CGSizeMake(40, 40), contentMode: .AspectFit, options: nil) { (image, info) in
                        self.images[index] = image
                        let indexPath = NSIndexPath(forRow: index, inSection: 0)
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    }
                })
            }
        }
    }
    var images = [UIImage?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = collection.localizedTitle
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let result = assetsResult {
            return result.count
        }
        return 0
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PhotoCellID", forIndexPath: indexPath)
        
        let asset = assetsResult![indexPath.row] as! PHAsset
        cell.textLabel?.text = asset.title
        cell.imageView?.image = images[indexPath.row]
        
        return cell
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
     if editingStyle == .Delete {
     // Delete the row from the data source
     tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
     } else if editingStyle == .Insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
