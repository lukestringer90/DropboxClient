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

class FilesViewController: UITableViewController, NetworkActivity, DropboxController {
    
    // MARK: Public Properties
    
    // Uses the root Dropbox folder by default
    var folder = Folder(name: "Dropbox", path: "", folders: nil, files: nil) {
        didSet {
            title = folder.name
        }
    }
    
    // MARK: Private Properites
    
    private let foldersIndexSet = NSIndexSet(index: TableSection.folders.rawValue)
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
                    tableView.insertSections(foldersIndexSet, withRowAnimation: .Top)
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
                    tableView.deleteSections(foldersIndexSet, withRowAnimation: .Top)
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
    
    // MARK: Outlets
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var deselectAllButton: UIBarButtonItem!
    @IBOutlet weak var selectAllButton: UIBarButtonItem!
    @IBOutlet weak var downloadButton: UIBarButtonItem!
    
    // MARK: UIViewController
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        state = .loading
        loadContentsOf(folder) { result in
            
            dispatch_async(dispatch_get_main_queue(),{
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
        let file: FileType
        
        if state == .selecting {
            (cell, file) = cellAndFile(forIndexPath: indexPath)
        }
        else {
            switch indexPath.section {
            case TableSection.folders.rawValue:
                (cell, file) = cellAndFolder(forIndexPath: indexPath)
            case TableSection.files.rawValue:
                (cell, file) = cellAndFile(forIndexPath: indexPath)
            default:
                fatalError("Unknown section")
            }
        }
        
        cell.textLabel?.text = file.name
        
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
    
    func cellAndFile(forIndexPath indexPath: NSIndexPath) -> (cell: UITableViewCell, file: FileType) {
        return (dequeCell(.File), folder.files![indexPath.row])
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
    }
    @IBAction func selectAllTapped(sender: AnyObject) {
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
