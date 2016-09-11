//
//  DirectoryViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/08/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

private enum State {
    case loading
    case viewing
    case selecting
    case downloading
}

private enum TableSection: Int {
    case folders
    case files
    case count
}

class FilesViewController: UITableViewController, NetworkActivity, LoadFolderContents, SaveThumbnail {
    
    // MARK: Public Properties
    
    // Uses the root Dropbox folder by default
    var folder = Folder(name: "Dropbox", path: "", folders: nil, files: nil) {
        didSet {
            title = folder.name
        }
    }
    
    // MARK: Private Properites
    
    private let foldersIndexSetWhenViewing = NSIndexSet(index: TableSection.folders.rawValue)
    
    private var state = State.loading {
        didSet {
            switch state {
                
            case .loading:
                selectButton.enabled = false
                showActivityIndicator()
                
            case .viewing:
                selectButton.enabled = true
                selectButton.title = "Select"
                navigationItem.setHidesBackButton(false, animated: true)
                navigationController?.setToolbarHidden(true, animated: true)
                hideActivityIndicator()
                
                if oldValue == .selecting {
                    tableView.insertSections(foldersIndexSetWhenViewing, withRowAnimation: .Top)
                }
                
            case .selecting:
                selectButton.title = "Cancel"
                navigationItem.setHidesBackButton(true, animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
                self.hideActivityIndicator()
                
                if oldValue == .downloading {
                    downloadButton.title = "Download"
                    selectButton.enabled = true
                    deselectAllButton.enabled = true
                    selectAllButton.enabled = true
                    self.hideActivityIndicator()
                }
                else if oldValue == .viewing {
                    tableView.deleteSections(foldersIndexSetWhenViewing, withRowAnimation: .Top)
                }
                
            case .downloading:
                selectButton.enabled = false
                deselectAllButton.enabled = false
                selectAllButton.enabled = false
                downloadButton.title = "Stop"
                self.showActivityIndicator()
            }
        }
    }
    
    private var selectedFolder: Folder? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let folders = folder.folders else {
            fatalError("Could not get selected folder")
        }
        
        return folders[indexPath.row]
    }
    
    private var selectedFiles = [File]()
    
    // MARK: Outlets
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var deselectAllButton: UIBarButtonItem!
    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    
    // MARK: UIViewController
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        state = .loading
        loadContents(of: folder) { result in
            
            dispatch_async(dispatch_get_main_queue(), {
                self.state = .viewing
                
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
}

// MARK: Table View Controller

extension FilesViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch state {
        case .loading:
            return 0
        case .selecting:
            return 1
        default:
            return TableSection.count.rawValue
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if state == .selecting {
            return folder.filesCount
        }
        
        switch TableSection(rawValue: section)! {
        case .folders:
            return folder.foldersCount
        case .files:
            return folder.filesCount
        default:
            fatalError("Unknown section")
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let fileType: FileType
        
        if state == .selecting {
            (cell, fileType) = cellAndFile(forIndexPath: indexPath)
        }
        else {
            switch indexPath.section {
            case TableSection.folders.rawValue:
                (cell, fileType) = cellAndFolder(forIndexPath: indexPath)
            case TableSection.files.rawValue:
                (cell, fileType) = cellAndFile(forIndexPath: indexPath)
            default:
                fatalError("Unknown section")
            }
        }
        
        cell.textLabel?.text = fileType.name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if state == .selecting {
            return "Files (\(folder.filesCount))"
        }
        
        switch section {
        case TableSection.folders.rawValue:
            return "Folders (\(folder.foldersCount))"
        case TableSection.files.rawValue:
            return "Files (\(folder.filesCount))"
        default:
            fatalError("Unknown section")
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard state == .selecting else { return }
        
        let (_, fileType) = cellAndFile(forIndexPath: indexPath)
        let file = fileType as! File
        
        if selectedFiles.contains(file) {
            let fileIndex = selectedFiles.indexOf(file)!
            selectedFiles.removeAtIndex(fileIndex)
        }
        else {
            selectedFiles.append(file)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    func cellAndFile(forIndexPath indexPath: NSIndexPath) -> (cell: UITableViewCell, file: FileType) {
        let (cell, file) = (dequeCell(.File), folder.files![indexPath.row])
        cell.accessoryType = selectedFiles.contains(file) ? .Checkmark : .None
        
        if let thumbnail = file.thumbnail {
            cell.imageView?.image = thumbnail
        }
        else {
            saveThumbnail(for: file, completion: { (thumbnailURL) in 
                dispatch_async(dispatch_get_main_queue(), {
                    if thumbnailURL != nil {
                        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    }
                })
            })
        }
        return (cell, file)
    }
    
    func cellAndFolder(forIndexPath indexPath: NSIndexPath) -> (cell: UITableViewCell, folder: FileType) {
        return (dequeCell(.Folder), folder.folders![indexPath.row])
    }
    
}

// MARK: IBActions

extension FilesViewController {
    
    @IBAction func selectTapped(sender: AnyObject) {
        state = state == .selecting ? .viewing : .selecting
    }
    
    @IBAction func deselectAllTapped(sender: AnyObject) {
        selectedFiles = []
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    @IBAction func selectAllTapped(sender: AnyObject) {
        if let allfiles = folder.files {
            selectedFiles = allfiles
        }
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    @IBAction func downloadTapped(sender: AnyObject) {
        state = state == .downloading ? .selecting : .downloading
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
