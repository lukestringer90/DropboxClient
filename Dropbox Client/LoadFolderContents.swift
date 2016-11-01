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
            
            let foldersMetadata = result.entries.folders()
            let folders = foldersMetadata.map { (metadata) -> Folder in
                return Folder(name: metadata.name, path: metadata.pathLower!, folders: nil, media: nil)
            }
            
            
            let filesMetaData = result.entries.files().sorted()
            let media = filesMetaData.map { (metadata) -> MediaFile in
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
                
                return MediaFile(id: metadata.id, name: metadata.name, path: metadata.pathLower!, description: description)
                
            }
            
            let newFolder = Folder(name: folder.name, path: folder.path, folders: folders, media: media)
            
            completion(.success(newFolder))
        }
    }
}
