//
//  UploadRequest.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

enum UploadState: String {
    case waiting
    case uploading
    case uploaded
}


class UploadRequest {
    let image: UploadableImage
    
    typealias CompletionHandler = (response: UploadResponse?, error: ErrorType?) -> Void
    var completionHandler: CompletionHandler? = nil
    
    typealias ProgressHandler = (progress: Float) -> Void
    var progressHandler: ProgressHandler? = nil
    
    var response: UploadResponse? = nil
    
    var progress: Float = 0 {
        didSet {
            progressHandler?(progress: progress)
            if progress >= 1 {
                state = .uploaded
                response = UploadResponse(image: image, fileSize: 100, uplodDate: NSDate())
                completionHandler?(response: response, error: nil)
            }
        }
    }
    var state: UploadState = .waiting
    
    init(image: UploadableImage, state: UploadState = .waiting) {
        self.image = image
    }
    
    func start() {
        state = .uploading
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

struct UploadResponse {
    let image: UploadableImage
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

struct UploadableImage {
    let title: String
    let image: UIImage?
}