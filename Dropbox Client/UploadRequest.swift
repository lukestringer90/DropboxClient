    //
//  UploadRequest.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

enum UploadState: String {
    case waiting
    case uploading
    case uploaded
    case failed
}

enum UploadError: ErrorType {
    case failure
}
    
class UploadRequest {
    let manifest: UploadManifest
    
    typealias CompletionHandler = (response: UploadResponse?) -> Void
    var completionHandler: CompletionHandler? = nil
    
    typealias ProgressHandler = (progress: Float) -> Void
    var progressHandler: ProgressHandler? = nil
    
    var response: UploadResponse? = nil
    
    var progress: Float = 0 {
        didSet {
            progressHandler?(progress: progress)
        }
    }
    var state: UploadState = .waiting
    
    init(manifest: UploadManifest, state: UploadState = .waiting) {
        self.manifest = manifest
    }
    
    func start(uploadFolderPath folderPath: String) {
        state = .uploading
        progress = 0
        
        let client = Dropbox.authorizedClient!
        let imagePath = "\(folderPath)/\(manifest.fileName)"
        let request = client.files.upload(path: imagePath, input: manifest.imageData)
        
        request.response({ (response, error) in
            if error != nil {
                self.state = .failed
                self.response = nil
            }
            else {
                self.state = .uploaded
                self.response = UploadResponse(manifest: self.manifest, folderPath: folderPath, fileSize: 100, uplodDate: NSDate())
            }
            
            self.completionHandler?(response: nil)
        })
        
        request.progress { (_, current, total) in
            let progress: Float = Float(current) / Float(total)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.progress = progress
            })
        }
    }
}

struct UploadResponse {
    let manifest: UploadManifest
    let folderPath: String
    let fileSize: Float
    let uplodDate: NSDate
}

