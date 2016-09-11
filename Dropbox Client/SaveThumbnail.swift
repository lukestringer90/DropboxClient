//
//  SaveThumbnail.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 11/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox
import Result

typealias ThumbnailCompletion = (NSURL?) -> ()

protocol SaveThumbnail {
    func saveThumbnail(for file: File, completion: ThumbnailCompletion)
}

extension SaveThumbnail where Self: UIViewController {
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