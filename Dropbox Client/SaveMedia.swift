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
    
        ProgressManager.sharedInstance.mediaFileProgressMap[mediaFile] = 0.0
        
        Timer.every(0.1) { (timer: Timer) in
            let currentProgress = ProgressManager.sharedInstance.mediaFileProgressMap[mediaFile]!
            let newProgress = currentProgress + 0.05
            
            ProgressManager.sharedInstance.mediaFileProgressMap[mediaFile] = newProgress
            
            if let saveProgress = progress {
                saveProgress(mediaFile, newProgress)
            }
            if (newProgress >= 1) {
                completion(.success(mediaFile))
                timer.invalidate()
            }
        }
    }
}

class ProgressManager {
    var mediaFileProgressMap = [MediaFile:Float]()
    static let sharedInstance = ProgressManager()
}
