//
//  FilesMetadataHelpers.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 01/11/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox

extension Array where Element:Files.Metadata {
    func mounted() -> [Files.Metadata] {
        return self.filter { $0.pathLower != nil }
    }
    
    func folders() -> [Files.FolderMetadata] {
        return self.mounted().filter { $0 is Files.FolderMetadata } as! [Files.FolderMetadata]
    }
    
    func files() -> [Files.FileMetadata] {
        return self.mounted().filter { $0 is Files.FileMetadata && $0.mediaType() != nil } as! [Files.FileMetadata]
    }
}

extension Array where Element:Files.FileMetadata {
    func sorted() -> [Files.FileMetadata] {
        return self.filter { $0.mediaInfo != nil }.sorted(by: { (itemA, itemb) -> Bool in
            let mediaInfoA = itemA.mediaInfo!
            let mediaInfoB = itemb.mediaInfo!
            
            switch mediaInfoA {
            case .metadata(let metadataA):
                switch mediaInfoB {
                case .metadata(let metadataB):
                    guard let dateA = metadataA.timeTaken, let dateB = metadataB.timeTaken else { return false }
                    return dateA.compare(dateB) == .orderedAscending
                default:
                    return false
                }
            default:
                return false
            }
        })
        
    }
}

extension Files.Metadata {
    
    enum MediaType {
        case image, video
    }
    
    func mediaType() -> MediaType? {
        let imageSuffixes = ["jpg", "jpeg", "png", "gif", "exif", "tiff", "bmp"]
        let videoSuffixes = ["webm", "mkv", "flv", "avi", "mov", "qt", "mp4", "m4v"]
        
        for imageSuffix in imageSuffixes {
            if self.name.lowercased().hasSuffix(imageSuffix) {
                return .image
            }
        }
        
        for videoSuffix in videoSuffixes {
            if self.name.lowercased().hasSuffix(videoSuffix) {
                return .video
            }
        }
        
        return nil
    }
}
