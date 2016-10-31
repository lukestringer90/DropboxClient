//
//  Folder.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 31/10/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

struct Folder: FileType {
    let name: String
    let path: String
    let folders: [Folder]?
    let media: [MediaFile]?
}

extension Folder {
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
