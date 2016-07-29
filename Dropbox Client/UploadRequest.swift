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
}
    
class UploadRequest {
    let manifest: UploadManifest
    
    typealias CompletionHandler = (response: UploadResponse?, error: ErrorType?) -> Void
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
        
        guard let (imageData, prefix) = dataFromImage(manifest.image) else {
            return
        }
        
        let client = Dropbox.authorizedClient!
        let imagePath = "\(folderPath)/\(manifest.title).\(prefix)"
        let request = client.files.upload(path: imagePath, input: imageData)
        
        request.response({ (_, uploadError) in
            if let error = uploadError {
                // Pass error here
                self.completionHandler?(response: nil, error: nil)
            }
            else {
                self.state = .uploaded
                self.response = UploadResponse(manifest: self.manifest, fileSize: 100, uplodDate: NSDate())
                self.completionHandler?(response: self.response, error: nil)
            }
        })
        
        request.progress { (_, current, total) in
            let progress: Float = Float(current) / Float(total)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.progress = progress
            })
        }
    }
    
    func dataFromImage(image: UIImage) -> (imageData: NSData, prefix: String)? {
        if let pngData = UIImagePNGRepresentation(image) {
            return (pngData, "png")
        }
        else if let jpegData = UIImageJPEGRepresentation(image, 1) {
            return (jpegData, "jpg")
        }

        return nil
    }
}

struct UploadResponse {
    let manifest: UploadManifest
    let fileSize: Float
    let uplodDate: NSDate
}

extension UploadResponse {
    func cellDescription() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd/MM HH:mm"
        return "\(self.fileSize)MB, uploaded \(dateFormatter.stringFromDate(self.uplodDate))"
    }
}

