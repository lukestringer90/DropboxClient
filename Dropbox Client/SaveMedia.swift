//
//  SaveMedia.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 12/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import SwiftyDropbox
import Result
import SwiftyTimer

enum SaveMediaError: ErrorType {
    case dropbox
    case photos
    case unknown
}

typealias SaveMediaCompletion = (Result<MediaFile, SaveMediaError>) -> ()
typealias SaveMediaProgress = (mediaFile: MediaFile, progress: Float) -> ()

protocol SaveMedia {
    func save(mediaFile: MediaFile, progress: SaveMediaProgress?, completion: SaveMediaCompletion)
}

extension SaveThumbnail where Self: UIViewController {
    
    func save(mediaFile: MediaFile, progress: SaveMediaProgress?, completion: SaveMediaCompletion) {
    
        ProgressManager.sharedInstance.mediaFileProgressMap[mediaFile] = 0.0
        
        NSTimer.every(0.1) { (timer: NSTimer) in
            let currentProgress = ProgressManager.sharedInstance.mediaFileProgressMap[mediaFile]!
            let newProgress = currentProgress + 0.05
            
            ProgressManager.sharedInstance.mediaFileProgressMap[mediaFile] = newProgress
            
            if let saveProgress = progress {
                saveProgress(mediaFile: mediaFile, progress: newProgress)
            }
            if (newProgress >= 1) {
                completion(.Success(mediaFile))
                timer.invalidate()
            }
        }
    }
}

class ProgressManager {
    var mediaFileProgressMap = [MediaFile:Float]()
    static let sharedInstance = ProgressManager()
}