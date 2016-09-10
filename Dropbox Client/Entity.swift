//
//  Folder.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 08/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import Foundation

protocol FileType {
    var name: String { get }
    var path: String { get }
}

struct Folder: FileType {
    let name: String
    let path: String
    let folders: [Folder]?
    let files: [File]?
    
    var foldersCount: Int {
        get {
            guard let folders = self.folders else { return 0 }
            return folders.count
        }
    }
    
    var filesCount: Int {
        get {
            guard let files = self.files else { return 0 }
            return files.count
        }
    }
}

struct File: FileType {
    let name: String
    let path: String
}