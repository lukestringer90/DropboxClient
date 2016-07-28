//
//  FolderViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 24/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

struct Folder {
    let path: String
    let name: String
}

class FolderViewController: UITableViewController {
    
    var foldersMetaData: Array<Files.Metadata> = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var folder = Folder(path: "", name: "Dropbox") {
        didSet {
            title = folder.name
        }
    }
    
    // MARK: UIViewController

    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        title = folder.name
        loadFoldersAtPath(folder.path)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            switch identifier {
            case "DismissToUploadPhotosWithFolder", "DismissToUploadPhotos":
                hideActivityIndicator()
            default:
                break
            }
        }
    }

    // MARK: FolderViewController
    
    func loadFoldersAtPath(path: String) {
        
        showActivityIndicator()
        
        let client = Dropbox.authorizedClient!
        let result = client.files.listFolder(path: path)
        result.response { (folderResult, error) in
            
            self.hideActivityIndicator()
            if let result = folderResult {
                self.foldersMetaData = result.entries.filter { $0 is SwiftyDropbox.Files.FolderMetadata }
            }
            else {
                print(error!)
            }
        }
    }
    
    func showActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func hideActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return foldersMetaData.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FolderCellID", forIndexPath: indexPath)

        cell.textLabel?.text = foldersMetaData[indexPath.row].name

        return cell
    }
 

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let folderMetaData = foldersMetaData[indexPath.row]
        let folder = Folder(path: folderMetaData.pathLower!, name: folderMetaData.name)
        let folderVC = storyboard?.instantiateViewControllerWithIdentifier("FolderViewControllerID") as! FolderViewController
        folderVC.folder = folder
        navigationController?.pushViewController(folderVC, animated: true)
    }

}
