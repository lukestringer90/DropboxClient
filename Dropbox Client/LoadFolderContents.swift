//
//  DropboxController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 10/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox
import Result

enum LoadFolderContentsError: Error {
    case folderAPI(error: CallError<Files.ListFolderError>)
    case unknown
}

typealias FolderCompletion = (Result<Folder, LoadFolderContentsError>) -> ()

protocol LoadFolderContents {
    func loadContents(of folder: Folder, completion: @escaping FolderCompletion)
}

extension LoadFolderContents where Self: UIViewController {
    
    func loadContents(of folder: Folder, completion: @escaping FolderCompletion) {
        
        guard let client = DropboxClientsManager.authorizedClient else {
            DropboxClientsManager.authorize(fromController: self)
            return
        }
        
        let result = client.files.listFolder(path: folder.path, recursive: false, includeMediaInfo: true, includeDeleted: false, includeHasExplicitSharedMembers: true)
        _ = result.response { (listFolderResult, listFolderError) in
            
            guard let result = listFolderResult else {
                if let APIError = listFolderError {
                    completion(.failure(.folderAPI(error: APIError)))
                }
                else {
                    completion(.failure(.unknown))
                }
                return
            }
            
            let mountedEntries = result.entries.filter { $0.pathLower != nil }
            let foldersMetadata = mountedEntries.filter { $0 is Files.FolderMetadata }
            let filesMetaData = mountedEntries.filter { $0 is Files.FileMetadata } as! [Files.FileMetadata]
            let sortedMediaMetaData = filesMetaData.filter { $0.mediaInfo != nil }.sorted(by: { (itemA, itemb) -> Bool in
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
            
            let folders = foldersMetadata.map { (metadata) -> Folder in
                return Folder(name: metadata.name, path: metadata.pathLower!, folders: nil, media: nil)
            }
            
            let media = sortedMediaMetaData.map { (metadata) -> MediaFile in
                let description: String?
                switch metadata.mediaInfo! {
                case .metadata(let mediaInfoMetadata):
                    guard let date = mediaInfoMetadata.timeTaken else {
                        description = nil
                        break
                    }
                    description = date.userFriendlyString()
                case .pending:
                    description = nil
                }
                return MediaFile(name: metadata.name, path: metadata.pathLower!, description: description)
                
                
            }
            
            let newFolder = Folder(name: folder.name, path: folder.path, folders: folders, media: media)
            
            completion(.success(newFolder))
        }
    }
}
