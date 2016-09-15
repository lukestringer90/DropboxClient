//
//  DropboxHelpers.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 15/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

extension Dropbox {
    static func authorize(fromController controller: UIViewController) {
        Dropbox.authorizeFromController(UIApplication.sharedApplication(), controller: controller, openURL: {(url: NSURL) -> Void in
            UIApplication.sharedApplication().openURL(url)})
    }
}
