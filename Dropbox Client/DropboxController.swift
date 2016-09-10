//
//  DropboxController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 10/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox
import Result

enum DropboxControllerError: ErrorType {
    case APIError(APIError: CallError<Files.ListFolderError>)
    case unknown
}

typealias DropboxCompletion = (Result<Folder, DropboxControllerError>) -> ()

protocol DropboxController {
    func loadContentsOf(folder: Folder, completion: DropboxCompletion)
}

extension DropboxController where Self: UIViewController {
    func loadContentsOf(folder: Folder, completion: DropboxCompletion) {
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        client.files.listFolder(path: folder.path).response { (listFolderResult, listFolderError) in
            
            guard let result = listFolderResult else {
                if let APIError = listFolderError {
                    completion(Result.Failure(DropboxControllerError.APIError(APIError: APIError)))
                }
                else {
                    completion(Result.Failure(DropboxControllerError.unknown))
                }
                return
            }
            
            let mountedEntries = result.entries.filter { $0.pathLower != nil }
            let foldersMetadata = mountedEntries.filter { $0 is Files.FolderMetadata }
            let filesMetadata = mountedEntries.filter { $0 is Files.FileMetadata } as! [Files.FileMetadata]
            
            let folders = foldersMetadata.map { (metadata) -> Folder in
                return Folder(name: metadata.name, path: metadata.pathLower!, folders: nil, files: nil)
            }
            
            let files = filesMetadata.map { (metadata) -> File in
                return File(name: metadata.name, path: metadata.pathLower!)
            }
            
            let newFolder = Folder(name: folder.name, path: folder.path, folders: folders, files: files)
            
            completion(Result.Success(newFolder))
        }
    }
    
}
