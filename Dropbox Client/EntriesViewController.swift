//
//  DirectoryViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/08/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

class FolderViewController: UITableViewController {
    
    // MARK: Public Properties
    
    var folder: Folder? {
        didSet {
            title = folder?.name
        }
    }
    
    // MARK: Private Properites
   
    private var isLoading = true {
        didSet {
            if isLoading {
                self.showActivityIndicator()
                selectButton.enabled = false
            }
            else {
                self.hideActivityIndicator()
                selectButton.enabled = true
            }
        }
    }
    
    enum TableSection: Int {
        case folders
        case images
        case count
    }
    
    private var selectedFolder: Folder? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let folder = self.folder, let folders = folder.folders else {
            fatalError("Could not get selected folder")
        }
        
        return folders[indexPath.row]
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    
    // MARK: UIViewController
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if folder == nil {
            let file1 = File(name: "File 1", path: "/File 1")
            let file2 = File(name: "File 2", path: "/File 2")
            let file3 = File(name: "File 3", path: "/File 3")
            let folderA = Folder(name: "Folder A", path: "/Folder A", folders: nil, files: [file3])
            let folderB = Folder(name: "Folder B", path: "/Folder B", folders: nil, files: nil)
            folder = Folder(name: "Dropbox", path: "/", folders: [folderA, folderB], files: [file1, file2])
        }
        loadFoldersAtPath(folder!.path)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if isLoading { return 0 }
        return TableSection.count.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch TableSection(rawValue: section)! {
        case .folders:
            if let folders = folder?.folders {
                return folders.count
            }
        case .images:
            if let images = folder?.files {
                return images.count
            }
        default:
            fatalError("Unknown section")
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let entity: Entity
        
        switch indexPath.section {
        case TableSection.folders.rawValue:
            cell = dequeCell(.Folder)
            entity = folder!.folders![indexPath.row]
        case TableSection.images.rawValue:
            cell = dequeCell(.File)
            entity = folder!.files![indexPath.row]
        default:
            fatalError("Unknown section")
        }

        cell.textLabel?.text = entity.name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case TableSection.folders.rawValue:
            return "Folders (\(folder!.foldersCount))"
        case TableSection.images.rawValue:
            return "Files (\(folder!.filesCount))"
        default:
            fatalError("Unknown section")
        }

    }
}


// MARK: IBActions
extension FolderViewController {
    
    @IBAction func selectTapped(sender: AnyObject) {
        
    }
}

// MARK: Dropbox

extension FolderViewController {
    
    func loadFoldersAtPath(path: String) {
        self.isLoading = false
        self.tableView.reloadData()
        return
        
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        isLoading = true
        
//        let result = client.files.listFolder(path: path)
//        result.response { (folderResult, error) in
//            
//            if let result = folderResult {
//                self.folders = result.entries.filter { $0 is Files.FolderMetadata } as? [Files.FolderMetadata]
//                self.images = result.entries.filter { $0 is Files.FileMetadata } as? [Files.FileMetadata]
//                self.isLoading = false
//                self.tableView.reloadData()
//            }
//            else {
//                print(error!)
//            }
//        }
    }
    
    func showActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func hideActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

extension FolderViewController: TableViewCellIdentifierType {
    enum TableViewCellIdentifier: String {
        case Folder
        case File
    }
}

extension FolderViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case ShowFolder
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowFolder:
            
            guard let folder = self.selectedFolder else { fatalError("Should have a path to segue to") }
            
            let foldersViewController = segue.destinationViewController as! FolderViewController
            foldersViewController.folder = folder
            foldersViewController.title = folder.name
        }
    }
}
