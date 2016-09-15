//
//  DropboxController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 10/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox
import Result

enum LoadFolderContentsError: ErrorType {
    case folderAPI(error: CallError<Files.ListFolderError>)
    case unknown
}

typealias FolderCompletion = (Result<Folder, LoadFolderContentsError>) -> ()

protocol LoadFolderContents {
    func loadContents(of folder: Folder, completion: FolderCompletion)
}

extension LoadFolderContents where Self: UIViewController {
    
    func loadContents(of folder: Folder, completion: FolderCompletion) {
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorize(fromController: self)
            return
        }
        
        let result = client.files.listFolder(path: folder.path, recursive: false, includeMediaInfo: true, includeDeleted: false, includeHasExplicitSharedMembers: false)
        result.response { (listFolderResult, listFolderError) in
            
            guard let result = listFolderResult else {
                if let APIError = listFolderError {
                    completion(.Failure(.folderAPI(error: APIError)))
                }
                else {
                    completion(.Failure(.unknown))
                }
                return
            }
            
            let mountedEntries = result.entries.filter { $0.pathLower != nil }
            let foldersMetadata = mountedEntries.filter { $0 is Files.FolderMetadata }
            let filesMetaData = mountedEntries.filter { $0 is Files.FileMetadata } as! [Files.FileMetadata]
            let sortedMediaMetaData = filesMetaData.filter { $0.mediaInfo != nil }.sort({ (itemA, itemb) -> Bool in
                let mediaInfoA = itemA.mediaInfo!
                let mediaInfoB = itemb.mediaInfo!
                
                switch mediaInfoA {
                case .Metadata(let metadataA):
                    switch mediaInfoB {
                    case .Metadata(let metadataB):
                        guard let dateA = metadataA.timeTaken, let dateB = metadataB.timeTaken else { return false }
                        return dateA.laterDate(dateB) == dateB
                    default:
                        return false
                    }
                default:
                    return false
                }
            })
            
            let folders = foldersMetadata.map { (metadata) -> Folder in
                return Folder(name: metadata.name, path: metadata.pathLower!, folders: nil, media: nil)
            }
            
            let media = sortedMediaMetaData.map { (metadata) -> MediaFile in
                let description: String?
                switch metadata.mediaInfo! {
                case .Metadata(let mediaInfoMetadata):
                    guard let date = mediaInfoMetadata.timeTaken else {
                        description = nil
                        break
                    }
                    description = date.userFriendlyString()
                case .Pending:
                    description = nil
                }
                return MediaFile(name: metadata.name, path: metadata.pathLower!, description: description)
                
                
            }
            
            let newFolder = Folder(name: folder.name, path: folder.path, folders: folders, media: media)
            
            completion(.Success(newFolder))
        }
    }
}
