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
    case media
    case count
}

class FolderViewController: UITableViewController, NetworkActivity, LoadFolderContents, SaveThumbnail {
    
    // MARK: Public Properties
    
    // Uses the root Dropbox folder by default
    var folder = Folder(name: "Dropbox", path: "", folders: nil, media: nil) {
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
    
    private var selectedMedia = [MediaFile]()
    
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

extension FolderViewController {
    
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
            return folder.mediaCount
        }
        
        switch TableSection(rawValue: section)! {
        case .folders:
            return folder.foldersCount
        case .media:
            return folder.mediaCount
        default:
            fatalError("Unknown section")
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if state == .selecting {
            cell = configuredCellForMediaFile(atIndexPath: indexPath)
        }
        else {
            switch indexPath.section {
            case TableSection.folders.rawValue:
                cell = configuredCellForFolder(atIndexPath: indexPath)
            case TableSection.media.rawValue:
                cell = configuredCellForMediaFile(atIndexPath: indexPath)
            default:
                fatalError("Unknown section")
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if state == .selecting {
            return "Media (\(folder.mediaCount))"
        }
        
        switch section {
        case TableSection.folders.rawValue:
            return "Folders (\(folder.foldersCount))"
        case TableSection.media.rawValue:
            return "Media (\(folder.mediaCount))"
        default:
            fatalError("Unknown section")
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard state == .selecting else { return }
        
        let mediaFile = folder.media![indexPath.row]
        
        if selectedMedia.contains(mediaFile) {
            let fileIndex = selectedMedia.indexOf(mediaFile)!
            selectedMedia.removeAtIndex(fileIndex)
        }
        else {
            selectedMedia.append(mediaFile)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if state == .selecting || TableSection.media.rawValue == indexPath.section {
            return 70
        }
        return 44
    }
    
    // MARK: Helpers
    
    func configuredCellForMediaFile(atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let mediaFile = folder.media![indexPath.row]
        let cell = mediaFile.thumbnail == nil ? dequeMediaCell(.MediaLoading) : dequeMediaCell(.MediaLoaded)
        
        cell.filenameLabel.text = mediaFile.name
        cell.accessoryType = selectedMedia.contains(mediaFile) ? .Checkmark : .None
        cell.thumnailView?.image = nil
        
        if let thumbnail = mediaFile.thumbnail {
            cell.thumnailView?.image = thumbnail
        }
        else {
            saveThumbnail(for: mediaFile, completion: { (thumbnailURL) in
                dispatch_async(dispatch_get_main_queue(), {
                    if thumbnailURL != nil {
                        if let indexPathToReload = self.tableView.indexPathForCell(cell) {
                            self.tableView.reloadRowsAtIndexPaths([indexPathToReload], withRowAnimation: .Automatic)
                        }
                        
                    }
                })
            })
        }
        return cell
    }
    
    func configuredCellForFolder(atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = (dequeCell(.Folder))
        let subFolder = folder.folders![indexPath.row]
        cell.textLabel?.text = subFolder.name
        return cell
    }
    
}

// MARK: IBActions

extension FolderViewController {
    
    @IBAction func selectTapped(sender: AnyObject) {
        switch state {
        case .selecting:
            // TODO: This crashes if viewing a media file at the bottom and no folders are visible
            state = .viewing
            deselectAllTapped(sender)
        case .viewing:
            state = .selecting
        default:
            break
        }
    }
    
    @IBAction func deselectAllTapped(sender: AnyObject) {
        selectedMedia = []
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    @IBAction func selectAllTapped(sender: AnyObject) {
        if let media = folder.media {
            selectedMedia = media
        }
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
    @IBAction func downloadTapped(sender: AnyObject) {
        state = state == .downloading ? .selecting : .downloading
    }
}

extension FolderViewController: TableViewCellIdentifierType {
    enum TableViewCellIdentifier: String {
        case Folder
        case MediaLoading
        case MediaLoaded
        case MediaSaving
    }
    
    func dequeMediaCell(identifier: TableViewCellIdentifier) -> MediaCell {
        guard let mediaCell = dequeCell(identifier) as? MediaCell else {
            fatalError("Dequed cell is not a MediaCell")
        }
        return mediaCell
    }
}

extension FolderViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case ShowFolder
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowFolder:
            
            guard let folder = self.selectedFolder else { fatalError("Should have a folder to segue to") }
            
            let foldersViewController = segue.destinationViewController as! FolderViewController
            foldersViewController.folder = folder
            foldersViewController.title = folder.name
        }
    }
}
