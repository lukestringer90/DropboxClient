//
//  UploadManifest.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 29/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

struct UploadManifest {
    let image: UIImage
    let title: String
    
    let imageData: NSData
    let fileName: String
    
    init?(image: UIImage, title: String) {
        if let (computedImageData, computedPrefix) = computeImageDataAndPrefix(image: image) {
            self.image = image
            self.title = title
            self.imageData = computedImageData
            
            self.fileName = "\(self.title).\(computedPrefix)"
        }
        else {
            return nil
        }
    }
    
    // MARK: - Private helper
    
    private typealias ImageDataAndPrefixComputer = (image: UIImage) -> (imageData: NSData, filename: String)?
    
    private let computeImageDataAndPrefix: ImageDataAndPrefixComputer  =  { image in
        var imageData: NSData?
        var prefix: String?
        if let PNGData = UIImagePNGRepresentation(image) {
            imageData = PNGData
            prefix = "png"
        }
        else if let JPEGData = UIImageJPEGRepresentation(image, 1) {
            imageData = JPEGData
            prefix = "jpg"
        }
        else {
            return nil
        }
        
        return (imageData!, prefix!)
    }
}
