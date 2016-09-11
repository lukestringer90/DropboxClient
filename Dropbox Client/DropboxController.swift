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
    case folderAPI(error: CallError<Files.ListFolderError>)
    case unknown
}

typealias FolderCompletion = (Result<Folder, DropboxControllerError>) -> ()
typealias ThumbnailCompletion = (NSURL?) -> ()

protocol DropboxController {
    func loadContents(of folder: Folder, completion: FolderCompletion)
    func saveThumbnail(for file: File, completion: ThumbnailCompletion)
}

extension DropboxController where Self: UIViewController {
    
    func loadContents(of folder: Folder, completion: FolderCompletion) {
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        client.files.listFolder(path: folder.path).response { (listFolderResult, listFolderError) in
            
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
            let filesMetadata = mountedEntries.filter { $0 is Files.FileMetadata } as! [Files.FileMetadata]
            
            let folders = foldersMetadata.map { (metadata) -> Folder in
                return Folder(name: metadata.name, path: metadata.pathLower!, folders: nil, files: nil)
            }
            
            let files = filesMetadata.map { (metadata) -> File in
                return File(name: metadata.name, path: metadata.pathLower!)
            }
            
            let newFolder = Folder(name: folder.name, path: folder.path, folders: folders, files: files)
            
            completion(.Success(newFolder))
        }
    }
    
    func saveThumbnail(for file: File, completion: ThumbnailCompletion) {
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        let request = client.files.getThumbnail(path: file.path, format: .Png, size: .W64h64, overwrite: true) { (url, response) -> NSURL in
            return file.thumbnailURL
        }
        request.response { (result, error) in
            if let (_, url) = result {
                completion(url)
            }
            else if let _ = error {
                completion(nil)
            }
        }
    }
    
    
    
}
