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
    
    var progress: Float = 0 {
        didSet {
            progressHandler?(progress: progress)
        }
    }
    var state: UploadState = .waiting
    
    init(manifest: UploadManifest, state: UploadState = .waiting) {
        self.manifest = manifest
    }
    
    func startUploadToPath(folderPath: String) {
        state = .uploading
        progress = 0
        
        let client = Dropbox.authorizedClient!
        let imagePath = "\(folderPath)/\(manifest.fileName)"
        let request = client.files.upload(path: imagePath, input: manifest.imageData)
        
        request.response({ (metaData, error) in
            let uploadResponse: UploadResponse?
            if error != nil {
                self.state = .failed
                uploadResponse = nil
            }
            else {
                self.state = .uploaded
                uploadResponse = UploadResponse(manifest: self.manifest, folderPath: folderPath, fileSize: metaData?.size, uplodDate: NSDate())
            }
            
            self.completionHandler?(response: uploadResponse)
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
    let fileSize: UInt64?
    let uplodDate: NSDate
}

