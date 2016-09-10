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
        
        let result = client.files.listFolder(path: folder.path)
        result.response { (listFolderResult, listFolderError) in
            
            if let result = listFolderResult {
                let mountedEntries = result.entries.filter { $0.pathLower != nil }
                let mountedFoldersMetadata = mountedEntries.filter { $0 is Files.FolderMetadata }
                let mountedFilesMetadata = mountedEntries.filter { $0 is Files.FileMetadata }
                
                let folders = mountedFoldersMetadata.map({ (metadata) -> Folder in
                    return Folder(name: metadata.name, path: metadata.pathLower!, folders: nil, files: nil)
                })
                
                let files = mountedFilesMetadata.map({ (metadata) -> File in
                    return File(name: metadata.name, path: metadata.pathLower!)
                })
                
                let newFolder = Folder(name: folder.name, path: folder.path, folders: folders, files: files)
                
                completion(Result.Success(newFolder))
                
            }
            else if let APIError = listFolderError {
                completion(Result.Failure(DropboxControllerError.APIError(APIError: APIError)))
            }
            else {
                completion(Result.Failure(DropboxControllerError.unknown))
            }
        }
    }

}
