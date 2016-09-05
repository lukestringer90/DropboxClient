//
//  DirectoryViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/08/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

class FoldersViewController: UITableViewController {
    
    private var folders: [Files.FolderMetadata]?
    
    func loadFoldersAtPath(path: String) {
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        showActivityIndicator()
        
        let result = client.files.listFolder(path: path)
        result.response { (folderResult, error) in
            
            self.hideActivityIndicator()
            if let result = folderResult {
                self.folders = result.entries.filter { $0 is Files.FolderMetadata } as? [Files.FolderMetadata]
                self.tableView.reloadData()
            }
            else {
                print(error!)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFoldersAtPath("")
    }
    
    func showActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func hideActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let folders = self.folders {
            return folders.count
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = dequeCell(.Folder)
        
        let folder = folders![indexPath.row]
        cell.textLabel?.text = folder.name
        
        return cell
    }
}

extension FoldersViewController: TableViewCellIdentifierType {
    enum TableViewCellIdentifier: String {
        case Folder
    }
}
