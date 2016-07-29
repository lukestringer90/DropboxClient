//
//  PHAsset+Extension.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 25/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import Foundation
import Photos

extension PHAsset {
    var title: String {
        let dateFormatter = NSDateFormatter.imageTitleDateFormatter()
        return "Photo \(dateFormatter.stringFromDate(self.creationDate!))"
    }
}