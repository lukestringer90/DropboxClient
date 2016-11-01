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
    
    fileprivate var mediaFileProgressMap = [MediaFile:Float]()
    fileprivate var mediaFileBeingSaved: MediaFile? = nil
    fileprivate var showingPhotoLibraryAccessUnauthorizedAlert = false
    fileprivate let firstSectionIndexSet = IndexSet(integer: TableSection.folders.rawValue)
    
    fileprivate var state = State.loading {
        didSet {
            switch state {
                
            case .loading:
                showActivityIndicator()
                selectButton.isEnabled = false
                
            case .viewing:
                hideActivityIndicator()
                selectButton.isEnabled = true
                selectButton.title = "Select"
                navigationItem.setHidesBackButton(false, animated: true)
                
                if oldValue == .selecting {
                    tableView.insertSections(firstSectionIndexSet, with: .top)
                }
                
                navigationController?.setToolbarHidden(true, animated: true)
                
            case .selecting:
                self.hideActivityIndicator()
                selectButton.title = "Cancel"
                navigationItem.setHidesBackButton(true, animated: true)
                navigationController?.setToolbarHidden(false, animated: true)
                
                if oldValue == .saving {
                    saveButton.title = "Save"
                    selectButton.isEnabled = true
                    batchButton.isEnabled = true
                    tableView.reloadSections(firstSectionIndexSet, with: .automatic)
                }
                else if oldValue == .viewing {
                    tableView.deleteSections(firstSectionIndexSet, with: .top)
                }
                
            case .saving:
                guard selectedMedia.count > 0 else {
                    state = .selecting
                    break
                }
                self.showActivityIndicator()
                selectButton.isEnabled = false
                batchButton.isEnabled = false
                saveButton.title = "Stop"
                tableView.reloadSections(firstSectionIndexSet, with: .automatic)
                saveSelectedMediaFilesAsynchronously()
            }
        }
    }
    
    fileprivate var selectedFolder: Folder? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        
        guard let folders = folder.folders else {
            fatalError("Could not get selected folder")
        }
        
        return folders[(indexPath as NSIndexPath).row]
    }
    
    fileprivate var selectedMedia = [MediaFile]()
    
    // MARK: Outlets
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var batchButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
}

// MARK: View Controller

extension FolderViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        state = .loading
        loadContents(of: folder) { result in
            
            DispatchQueue.main.async(execute: {
                self.state = .viewing
                
                switch result {
                case .success(let newFolder):
                    self.folder = newFolder
                    self.tableView!.reloadData()
                case .failure(let error):
                    print(error)
                }
            })
        }
    }
    
}

// MARK: Table View Controller

extension FolderViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch state {
        case .loading:
            return 0
        case .selecting, .saving:
            return 1
        default:
            return TableSection.count.rawValue
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if state == .selecting || state == .saving {
            return configuredMediaCell(atIndexPath: indexPath)
        }
        else {
            switch (indexPath as NSIndexPath).section {
            case TableSection.folders.rawValue:
                return configuedFolderCell(atIndexPath: indexPath)
            case TableSection.media.rawValue:
                return configuredMediaCell(atIndexPath: indexPath)
            default:
                fatalError("Unknown section")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard state == .selecting else { return }
        
        let mediaFile = folder.media![(indexPath as NSIndexPath).row]
        
        if selectedMedia.contains(mediaFile) {
            let fileIndex = selectedMedia.index(of: mediaFile)!
            selectedMedia.remove(at: fileIndex)
        }
        else {
            selectedMedia.append(mediaFile)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if state == .selecting || state == .saving || TableSection.media.rawValue == (indexPath as NSIndexPath).section {
            return 70
        }
        return 44
    }
    
    // MARK: Helpers
    
    func configuredMediaCell(atIndexPath indexPath: IndexPath) -> MediaCell {
        
        // Deqgue media cell
        let mediaFile = folder.media![(indexPath as NSIndexPath).row]
        let cell = dequeCell(forMediaFile: mediaFile)
        
        // Text attributes
        cell.filenameLabel.text = mediaFile.name
        cell.descriptionLabel?.text = mediaFile.description
        
        // Selected state
        if (selectedMedia.contains(mediaFile) && state != .saving) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        // Save progress
        if state == .saving {
            if let mediaFileBeingSaved = mediaFileBeingSaved,
                mediaFileBeingSaved == mediaFile,
                let progress = mediaFileProgressMap[mediaFileBeingSaved] {
                let perctenage = progress * 100
                cell.percentageLabel?.text = String(format: "%.0f%%", perctenage)
                cell.progressView?.progress = progress
            }
        }
        
        // Tumbnail loading
        cell.thumnailView?.image = nil
        if let thumbnail = mediaFile.thumbnail {
            cell.thumnailView?.image = thumbnail
        }
        else {
            saveThumbnail(for: mediaFile, completion: { (thumbnailURL) in
                DispatchQueue.main.async(execute: {
                    if thumbnailURL != nil {
                        if let indexPathToReload = self.tableView.indexPath(for: cell) {
                            self.tableView.reloadRows(at: [indexPathToReload], with: .automatic)
                        }
                        
                    }
                })
            })
        }
        return cell
    }
    
    func dequeCell(forMediaFile mediaFile: MediaFile) -> MediaCell {
        
        func dequeMediaCell(_ identifier: TableViewCellIdentifier) -> MediaCell {
            guard let mediaCell = dequeCell(identifier) as? MediaCell else {
                fatalError("Dequed cell is not a MediaCell")
            }
            return mediaCell
        }
        
        if mediaFile.thumbnail == nil {
            return dequeMediaCell(.mediaLoading)
        }
        else if mediaFile.isSaved() {
            return dequeMediaCell(.mediaSaved)
        }
        
        switch state {
        case .saving:
            if selectedMedia.contains(mediaFile) {
                if let mediaFileBeingSaved = mediaFileBeingSaved, mediaFileBeingSaved == mediaFile {
                    return dequeMediaCell(.mediaSaving)
                }
                else  {
                    return dequeMediaCell(.mediaWaitingToSave)
                }
            }
            else {
                let cell = dequeMediaCell(.mediaLoaded)
                cell.selectionStyle = .none
                return cell
            }
            
        default:
            return dequeMediaCell(.mediaLoaded)
        }
    }
    
    func configuedFolderCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = (dequeCell(.folder))
        let subFolder = folder.folders![indexPath.row]
        cell.textLabel?.text = subFolder.name
        return cell
    }
    
}

// MARK: IBActions

extension FolderViewController {
    
    func selectTapped(_ sender: AnyObject) {
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
    
    func deselectAllTapped(_ sender: AnyObject) {
        selectedMedia = []
        tableView.reloadSections(firstSectionIndexSet, with: .automatic)
    }
    
    func allTapped(_ sender: AnyObject) {
        if let media = folder.media {
            selectedMedia = media
        }
        tableView.reloadSections(firstSectionIndexSet, with: .automatic)
    }
    
    func unsavedTapped(_ sender: AnyObject) {
        if let media = folder.media {
            selectedMedia = media.filter { !$0.isSaved() }
        }
        tableView.reloadSections(firstSectionIndexSet, with: .automatic)
    }
    
    @IBAction func batchTapped(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Perform Batch Action.", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Select All", style: .default, handler: allTapped))
        alert.addAction(UIAlertAction(title: "Select Un-saved", style: .default, handler: unsavedTapped))
        alert.addAction(UIAlertAction(title: "Deselect All", style: .default, handler: deselectAllTapped))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: AnyObject) {
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
        case mediaWaitingToSave
    }
}

// MARK: Saving Media
extension FolderViewController {
    
    func saveSelectedMediaFilesAsynchronously() {
        saveMediaFile(atIndex: 0)
    }
    
    func saveMediaFile(atIndex indexInSelected: Int) {
        mediaFileBeingSaved = selectedMedia[indexInSelected]
        
        let indexInAllMedia = folder.media!.index(of: mediaFileBeingSaved!)!
        let indexPath = IndexPath(row: indexInAllMedia, section: 0)
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        save(mediaFileBeingSaved!,
             progress: { (mediaFile, progress) in
                
                DispatchQueue.main.async(execute: {
                    
                    if let savingCell = self.tableView.cellForRow(at: indexPath) as? MediaCell {
                        let perctenage = progress * 100
                        savingCell.percentageLabel?.text = String(format: "%.0f%%", perctenage)
                        savingCell.progressView?.progress = progress
                    }
                    
                })
            },
             completion: { result in
                
                DispatchQueue.main.async(execute: {
                    
                    switch result{
                    case .failure(let error):
                        print("\(self.mediaFileBeingSaved?.name) errored: \(error)")
                        if error == .photosUnauthorized {
                            self.handlePhotoLibraryAccessUnauthorized()
                        }
                    default:
                        break
                    }
                    
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    
                    let nextIndex = indexInSelected + 1
                    if nextIndex < self.selectedMedia.count {
                        self.saveMediaFile(atIndex: nextIndex)
                    }
                    else {
                        self.deselectAllTapped(self)
                        self.mediaFileBeingSaved = nil
                        self.state = .selecting
                    }
                })
        })
    }
    
    func handlePhotoLibraryAccessUnauthorized() {
        if !showingPhotoLibraryAccessUnauthorizedAlert {
            showingPhotoLibraryAccessUnauthorizedAlert = true
            let alert = UIAlertController(title: "Photo Library Access Unauthorized", message: "Access to your Photo Library has not been authorized.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in
                self.showingPhotoLibraryAccessUnauthorizedAlert = false
            }))
            present(alert, animated: true)
        }
    }
}

extension FolderViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case ShowFolder
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifierForSegue(segue) {
        case .ShowFolder:
            
            guard let folder = self.selectedFolder else { fatalError("Should have a folder to segue to") }
            
            let foldersViewController = segue.destination as! FolderViewController
            foldersViewController.folder = folder
            foldersViewController.title = folder.name
        }
    }
}
