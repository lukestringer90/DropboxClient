//
//  SaveMedia.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 12/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox
import Result
import Photos

enum SaveMediaError: Error {
    case dropbox
    case photosUnauthorized
    case photosSave
    case unknown
}

typealias SaveMediaCompletion = (Result<MediaFile, SaveMediaError>) -> ()
typealias SaveMediaProgress = (_ mediaFile: MediaFile, _ progress: Float) -> ()

protocol SaveMedia {
    func save(_ mediaFile: MediaFile, progress: SaveMediaProgress?, completion: SaveMediaCompletion)
}

extension SaveThumbnail where Self: UIViewController {
    
    func save(_ mediaFile: MediaFile, progress: SaveMediaProgress?, completion: @escaping SaveMediaCompletion) {
        
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ (status) in
                guard status == .authorized else {
                    completion(.failure(.photosUnauthorized))
                    return
                }
                self.save(mediaFile, toAuthorizedLibrary: PHPhotoLibrary.shared(), progress: progress, completion: completion)
            })
        }
        else {
            self.save(mediaFile, toAuthorizedLibrary: PHPhotoLibrary.shared(), progress: progress, completion: completion)
        }
    }
    
    func save(_ mediaFile: MediaFile, toAuthorizedLibrary library: PHPhotoLibrary,  progress: SaveMediaProgress?, completion: @escaping SaveMediaCompletion) {
        
        guard let client = DropboxClientsManager.authorizedClient else {
            DropboxClientsManager.authorize(fromController: self)
            completion(.failure(.dropbox))
            return
        }
        
        let request = client.files.download(path: mediaFile.path, rev: nil, overwrite: true) { _, _ in
            return mediaFile.temporaryDownloadURL
        }
        
        _ = request.progress { (progressValue) in
            if let progressCallback = progress {
                progressCallback(mediaFile, Float(progressValue.fractionCompleted))
            }
        }
        
        _ = request.response { (response, error) in
            
            guard error == nil else {
                completion(.failure(.dropbox))
                return
            }
            
            if let metadata = response?.0, let mediaType = metadata.mediaType() {
                
                defer {
                    mediaFile.clearDownloadData()
                }
                
                do {
                    try library.performChangesAndWait {
                        switch mediaType {
                        case .image:
                            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: mediaFile.temporaryDownloadURL)
                        case .video:
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: mediaFile.temporaryDownloadURL)
                        }
                        completion(.success(mediaFile))
                    }
                }
                catch {
                    completion(.failure(.photosSave))
                }
            }
            else {
                completion(.failure(.unknown))
            }
        }
    }
    
}
