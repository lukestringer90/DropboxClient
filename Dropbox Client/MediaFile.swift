//
//  MediaFile.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 31/10/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import Photos

struct MediaFile: FileType {
    let id: String
    let name: String
    let path: String
    let description: String?
}

extension MediaFile {
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
