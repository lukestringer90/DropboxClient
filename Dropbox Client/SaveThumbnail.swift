//
//  SaveThumbnail.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 11/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox

typealias ThumbnailCompletion = (URL?) -> ()

protocol SaveThumbnail {
    func saveThumbnail(for mediaFile: MediaFile, completion: @escaping ThumbnailCompletion)
}

extension SaveThumbnail where Self: UIViewController {
    func saveThumbnail(for mediaFile: MediaFile, completion: @escaping ThumbnailCompletion) {
        
        guard let client = DropboxClientsManager.authorizedClient else {
            DropboxClientsManager.authorize(fromController: self)
            return
        }
        
        let request = client.files.getThumbnail(path: mediaFile.path, format: .png, size: .w64h64, overwrite: true) { (url, response) -> URL in
            return mediaFile.thumbnailURL
        }
        _ = request.response { (result, error) in
            if let (_, url) = result {
                completion(url)
            }
            else if let _ = error {
                completion(nil)
            }
        }
    }
}
