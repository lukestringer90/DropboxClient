//
//  NetworkActivity.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 10/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

protocol NetworkActivity {
    func showActivityIndicator()
    func hideActivityIndicator()
}

extension NetworkActivity {
    func showActivityIndicator() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func hideActivityIndicator() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
