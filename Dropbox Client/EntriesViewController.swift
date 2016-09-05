//
//  DirectoryViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/08/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

class EntriesViewController: UITableViewController {
    
    // MARK: Public Properties
    
    var path: String = ""
    
    // MARK: Private Properites
    
    private var entries: [Files.Metadata]?
    private var selectedFolder: Files.FolderMetadata? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let entries = self.entries, selectedFolder = entries[indexPath.row] as? Files.FolderMetadata else {
            fatalError("Could not get selected folder")
        }
        
        return selectedFolder
    }
    
    // MARK: UIViewController
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadFoldersAtPath(path)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let entries = self.entries {
            return entries.count
        }
        return 0
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let entry = entries![indexPath.row]
        
        let cellID: TableViewCellIdentifier = {
            switch entry {
            case is Files.FileMetadata:
                return .File
            case is Files.FolderMetadata:
                return .Folder
            default:
                fatalError("Unknown File Type")
            }
        }()
        
        let cell = dequeCell(cellID)
        cell.textLabel?.text = entry.name
        
        return cell
    }
}

// MARK: Dropbox

extension EntriesViewController {
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
                self.entries = result.entries
                self.tableView.reloadData()
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
}

extension EntriesViewController: TableViewCellIdentifierType {
    enum TableViewCellIdentifier: String {
        case Folder
        case File
    }
}

extension EntriesViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case ShowFolder
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowFolder:
            
            guard let folder = self.selectedFolder, path = folder.pathLower else { fatalError("Should have a path to segue to") }
            
            let foldersViewController = segue.destinationViewController as! EntriesViewController
            foldersViewController.path = path
            foldersViewController.title = folder.name
        }
    }
}
