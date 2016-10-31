//
//  Folder.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 08/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

protocol FileType {
    var name: String { get }
    var path: String { get }
}

struct Folder: FileType {
    let name: String
    let path: String
    let folders: [Folder]?
    let media: [MediaFile]?
    
    var foldersCount: Int {
        get {
            guard let folders = self.folders else { return 0 }
            return folders.count
        }
    }
    
    var mediaCount: Int {
        get {
            guard let files = self.media else { return 0 }
            return files.count
        }
    }
}

extension Folder: Equatable {}
func ==(lhs: Folder, rhs: Folder) -> Bool {
    return lhs.name == rhs.name && lhs.path == rhs.path
}

struct MediaFile: FileType {
    let name: String
    let path: String
    let description: String?
    
    var thumbnail: UIImage? {
        // Remove thumbnail after a period of time
        guard let imageData = try? Data(contentsOf: thumbnailURL),
            let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    var thumbnailURL: URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentsURL = URL(fileURLWithPath: documentsPath)
        return URL(fileURLWithPath: "\(self.name)-thumb", relativeTo: documentsURL)
    }
    
    var temporaryDownloadURL: URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentsURL = URL(fileURLWithPath: documentsPath)
        return URL(fileURLWithPath: "\(self.name)", relativeTo: documentsURL)
    }
    
    func clearDownloadData() {
        try? FileManager.default.removeItem(at: temporaryDownloadURL)
    }
}

extension MediaFile: Hashable {
    var hashValue: Int {
        get {
           return path.hashValue
        }
    }
}

extension MediaFile: Equatable {}
func ==(lhs: MediaFile, rhs: MediaFile) -> Bool {
    return lhs.name == rhs.name && lhs.path == rhs.path
}
