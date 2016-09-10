//
//  DirectoryViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/08/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

class FilesViewController: UITableViewController, NetworkActivity, DropboxController {
    
    // MARK: Public Properties
    
    // Uses the root Dropbox folder by default
    var folder = Folder(name: "Dropbox", path: "", folders: nil, files: nil) {
        didSet {
            title = folder.name
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
    
    private var isSelectingFiles = false {
        didSet {
            selectButton.title = isSelectingFiles ? "Cancel" : "Select"
            navigationItem.setHidesBackButton(isSelectingFiles, animated: true)
            navigationController?.setToolbarHidden(!isSelectingFiles, animated: true)
            
            // While loading we don't have any sections, so we cannot delete or insert
            guard !isLoading else { return }
            
            let foldersIndexSet = NSIndexSet(index: TableSection.folders.rawValue)
            if isSelectingFiles {
                tableView.deleteSections(foldersIndexSet, withRowAnimation: .Top)
            }
            else {
                tableView.insertSections(foldersIndexSet, withRowAnimation: .Top)
            }
        }
    }
    
    enum TableSection: Int {
        case folders
        case files
        case count
    }
    
    private var selectedFolder: Folder? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let folders = folder.folders else {
            fatalError("Could not get selected folder")
        }
        
        return folders[indexPath.row]
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    
    // MARK: UIViewController
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        isLoading = true
        isSelectingFiles = false
        loadContentsOf(folder) { result in
            
            dispatch_async(dispatch_get_main_queue(),{
                self.isLoading = false
                
                switch result {
                case .Success(let newFolder):
                    self.folder = newFolder
                    self.tableView!.reloadData()
                case .Failure(let error):
                    print(error)
                }
            })
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if isLoading { return 0 }
        if isSelectingFiles { return 1 }
        return TableSection.count.rawValue
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSelectingFiles {
            if let images = folder.files {
                return images.count
            }
        }
        
        
        switch TableSection(rawValue: section)! {
        case .folders:
            if let folders = folder.folders {
                return folders.count
            }
        case .files:
            if let images = folder.files {
                return images.count
            }
        default:
            fatalError("Unknown section")
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let file: FileType
        
        if isSelectingFiles {
            cell = dequeCell(.File)
            file = folder.files![indexPath.row]
        }
        else {
            switch indexPath.section {
            case TableSection.folders.rawValue:
                cell = dequeCell(.Folder)
                file = folder.folders![indexPath.row]
            case TableSection.files.rawValue:
                cell = dequeCell(.File)
                file = folder.files![indexPath.row]
            default:
                fatalError("Unknown section")
            }
        }
        
        
        
        cell.textLabel?.text = file.name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSelectingFiles { return "Files (\(folder.filesCount))" }
        
        switch section {
        case TableSection.folders.rawValue:
            return "Folders (\(folder.foldersCount))"
        case TableSection.files.rawValue:
            return "Files (\(folder.filesCount))"
        default:
            fatalError("Unknown section")
        }
        
    }
}


// MARK: IBActions
extension FilesViewController {
    
    @IBAction func selectTapped(sender: AnyObject) {
        isSelectingFiles = !isSelectingFiles
    }
}

extension FilesViewController: TableViewCellIdentifierType {
    enum TableViewCellIdentifier: String {
        case Folder
        case File
    }
}

extension FilesViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case ShowFolder
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowFolder:
            
            guard let folder = self.selectedFolder else { fatalError("Should have a folder to segue to") }
            
            let foldersViewController = segue.destinationViewController as! FilesViewController
            foldersViewController.folder = folder
            foldersViewController.title = folder.name
        }
    }
}
