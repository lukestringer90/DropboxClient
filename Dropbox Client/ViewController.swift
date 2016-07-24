//
//  ViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 24/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let client = Dropbox.authorizedClient else {
            Dropbox.authorizeFromController(self)
            return
        }
        
        // Get the current user's account info
        client.users.getCurrentAccount().response { response, error in
            print("*** Get current account ***")
            if let account = response {
                print("Hello \(account.name.givenName)!")
            } else {
                print(error!)
            }
        }

    }

}

