//
//  DropboxHelpers.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 15/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

extension DropboxClientsManager {
    static func authorize(fromController controller: UIViewController) {
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: controller, openURL: {(url: URL) -> Void in
            UIApplication.shared.openURL(url)}, browserAuth: false)
    }
}
