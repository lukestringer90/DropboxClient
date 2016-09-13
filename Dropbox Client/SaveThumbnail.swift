//
//  SaveThumbnail.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 11/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox

typealias ThumbnailCompletion = (NSURL?) -> ()

protocol SaveThumbnail {
    func saveThumbnail(for mediaFile: MediaFile, completion: ThumbnailCompletion)
}

extension SaveThumbnail where Self: UIViewController {
    func saveThumbnail(for mediaFile: MediaFile, completion: ThumbnailCompletion) {
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        let request = client.files.getThumbnail(path: mediaFile.path, format: .Png, size: .W64h64, overwrite: true) { (url, response) -> NSURL in
            return mediaFile.thumbnailURL
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