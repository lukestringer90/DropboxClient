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
        guard let imageData = NSData(contentsOfURL: thumbnailURL),
            let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    var thumbnailURL: NSURL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let documentsURL = NSURL(fileURLWithPath: documentsPath)
        return NSURL(fileURLWithPath: "\(self.name)", relativeToURL: documentsURL)
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