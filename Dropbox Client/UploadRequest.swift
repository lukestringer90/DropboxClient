//
//  UploadRequest.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

class UploadRequest {
    let image: UploadableImage
    
    typealias CompletionHandler = (image: UploadableImage, error: ErrorType?) -> Void
    var completionHandler: CompletionHandler? = nil
    
    typealias ProgressHandler = (progress: Float) -> Void
    var progressHandler: ProgressHandler? = nil
    
    var progress: Float = 0 {
        didSet {
            progressHandler?(progress: progress)
            if progress >= 1 {
                state = .Uploaded
                completionHandler?(image: image, error: nil)
            }
        }
    }
    var state: UploadState = .Waiting
    
    init(image: UploadableImage, state: UploadState = .Waiting) {
        self.image = image
    }
    
    func start() {
        state = .Uploading
        progress = 0
        
        NSTimer.every(0.5.seconds) { (timer: NSTimer) in
            if self.progress >= 1 {
                timer.invalidate()
            }
            else {
                self.progress += 0.2
            }
        }
    }
}

struct UploadableImage {
    let title: String
    let image: UIImage?
}