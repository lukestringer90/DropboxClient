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
    
    private var folders: [Files.FolderMetadata]?
    private var images: [Files.FileMetadata]?
    private var isLoading = true {
        didSet {
            if isLoading {
                self.showActivityIndicator()
                downloadAllButton.enabled = false
            }
            else {
                self.hideActivityIndicator()
                downloadAllButton.enabled = true
            }
        }
    }
    
    enum TableSection: Int {
        case folders
        case images
        case count
    }
    
    private var selectedFolder: Files.FolderMetadata? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let folders = self.folders else {
            fatalError("Could not get selected folder")
        }
        
        return folders[indexPath.row]
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var downloadAllButton: UIBarButtonItem!
    
    // MARK: UIViewController
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadFoldersAtPath(path)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if isLoading { return 0 }
        return TableSection.count.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case TableSection.folders.rawValue:
            if let folders = self.folders {
                return folders.count
            }
        case TableSection.images.rawValue:
            if let images = self.images {
                return images.count
            }
        default:
            return 0
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let entry: Files.Metadata
        
        switch indexPath.section {
        case TableSection.folders.rawValue:
            cell = dequeCell(.Folder)
            entry = self.folders![indexPath.row]
        case TableSection.images.rawValue:
            cell = dequeCell(.File)
            entry = self.images![indexPath.row]
        default:
            fatalError("Unknown section")
        }

        cell.textLabel?.text = entry.name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case TableSection.folders.rawValue:
            return "Folders (\(folders!.count))"
        case TableSection.images.rawValue:
            return "Files (\(images!.count))"
        default:
            fatalError("Unknown section")
        }

    }
}


// MARK: IBActions
extension EntriesViewController {
    
    @IBAction func downloadTapped(sender: AnyObject) {
        // TODO
    }
}

// MARK: Dropbox

extension EntriesViewController {
    
    func loadFoldersAtPath(path: String) {
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        isLoading = true
        
        let result = client.files.listFolder(path: path)
        result.response { (folderResult, error) in
            
            if let result = folderResult {
                self.folders = result.entries.filter { $0 is Files.FolderMetadata } as? [Files.FolderMetadata]
                self.images = result.entries.filter { $0 is Files.FileMetadata } as? [Files.FileMetadata]
                self.isLoading = false
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
