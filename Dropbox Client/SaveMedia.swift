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
    case photos
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
                guard PHPhotoLibrary.authorizationStatus() == .authorized else {
                    completion(.failure(.photos))
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
        
        print("Downloading: \(mediaFile.name)")
        
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
                print("Failed: \(error)")
                completion(.failure(.dropbox))
                return
            }
            
            if let metadata = response?.0, let mediaType = metadata.mediaType() {
                
                try! library.performChangesAndWait {
                    switch mediaType {
                    case .image:
                        print("Saving image")
                        PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: mediaFile.temporaryDownloadURL)
                    case .video:
                        print("Saving video")
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: mediaFile.temporaryDownloadURL)
                    }
                }
                mediaFile.clearDownloadData()
                completion(.success(mediaFile))
            }
            else {
                completion(.failure(.unknown))
            }
        }
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
