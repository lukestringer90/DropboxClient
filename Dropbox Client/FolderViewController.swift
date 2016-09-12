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
    case saving
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
    
    private let firstSectionIndexSet = NSIndexSet(index: TableSection.folders.rawValue)
    
    private var state = State.loading {
        didSet {
            switch state {
                
            case .loading:
                showActivityIndicator()
                selectButton.enabled = false
                
            case .viewing:
                hideActivityIndicator()
                selectButton.enabled = true
                selectButton.title = "Select"
                navigationItem.setHidesBackButton(false, animated: true)
                
                if oldValue == .selecting {
                    tableView.insertSections(firstSectionIndexSet, withRowAnimation: .Top)
                }
                
                navigationController?.setToolbarHidden(true, animated: true)
                
            case .selecting:
                self.hideActivityIndicator()
                selectButton.title = "Cancel"
                navigationItem.setHidesBackButton(true, animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
                
                if oldValue == .saving {
                    saveButton.title = "Save"
                    selectButton.enabled = true
                    deselectAllButton.enabled = true
                    selectAllButton.enabled = true
                    tableView.reloadSections(firstSectionIndexSet, withRowAnimation: .Automatic)
                }
                else if oldValue == .viewing {
                    tableView.deleteSections(firstSectionIndexSet, withRowAnimation: .Top)
                }
                
            case .saving:
                self.showActivityIndicator()
                selectButton.enabled = false
                deselectAllButton.enabled = false
                selectAllButton.enabled = false
                saveButton.title = "Stop"
                tableView.reloadSections(firstSectionIndexSet, withRowAnimation: .Automatic)
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
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
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
        case .selecting, .saving:
            return 1
        default:
            return TableSection.count.rawValue
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if state == .selecting || state == .saving {
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
        
        if state == .selecting || state == .saving {
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
        if state == .selecting || state == .saving {
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
        if state == .selecting || state == .saving || TableSection.media.rawValue == indexPath.section {
            return 70
        }
        return 44
    }
    
    // MARK: Helpers
    
    func configuredCellForMediaFile(atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let mediaFile = folder.media![indexPath.row]
        let cell: MediaCell = {
            if mediaFile.thumbnail == nil {
                return dequeMediaCell(.mediaLoading)
            }
            switch state {
            case .saving:
                return dequeMediaCell(.mediaSaving)
            default:
                return dequeMediaCell(.mediaLoaded)
            }
        }()
        
        cell.filenameLabel.text = mediaFile.name
        cell.descriptionLabel?.text = mediaFile.description
        cell.accessoryType = selectedMedia.contains(mediaFile) && state != .saving ? .Checkmark : .None
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
        let cell = (dequeCell(.folder))
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
            if selectedMedia.count > 0 {
                deselectAllTapped(sender)
            }
            state = .viewing
        case .viewing:
            state = .selecting
        default:
            break
        }
    }
    
    @IBAction func deselectAllTapped(sender: AnyObject) {
        selectedMedia = []
        tableView.reloadSections(firstSectionIndexSet, withRowAnimation: .Automatic)
    }
    
    @IBAction func selectAllTapped(sender: AnyObject) {
        if let media = folder.media {
            selectedMedia = media
        }
        tableView.reloadSections(firstSectionIndexSet, withRowAnimation: .Automatic)
    }
    
    @IBAction func saveTapped(sender: AnyObject) {
        state = state == .saving ? .selecting : .saving
    }
}

extension FolderViewController: TableViewCellIdentifierType {
    enum TableViewCellIdentifier: String {
        case folder
        case mediaLoading
        case mediaLoaded
        case mediaSaving
        case mediaSaved
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
