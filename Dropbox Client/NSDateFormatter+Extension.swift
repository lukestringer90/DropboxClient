//
//  NSDateFormatter+Extension.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 29/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import Foundation

extension NSDateFormatter {
    
    private static var _uploadedDateFormatter: NSDateFormatter? = nil
    static func uploadedDateFormatter() -> NSDateFormatter {
        
        if _uploadedDateFormatter == nil {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "dd/MM HH:mm"
            _uploadedDateFormatter = dateFormatter
        }
        
        return _uploadedDateFormatter!
    }
    
    private static var _imageTitleDateFormatter: NSDateFormatter? = nil
    static func imageTitleDateFormatter() -> NSDateFormatter {
        
        if _imageTitleDateFormatter == nil {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy, hh mm ss"
            _imageTitleDateFormatter = dateFormatter
        }
        
        return _imageTitleDateFormatter!
    }
}