//
//  DateHelpers.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 11/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import Foundation

extension NSDate {
    func userFriendlyString() -> String? {
        return NSDateFormatter.webAPIDateFormatter.stringFromDate(self)
    }
}

extension NSDateFormatter {
    
    private struct StaticVariables {
        
        static let userFriendlyFormatter: NSDateFormatter = {
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeStyle = .MediumStyle
            dateFormatter.dateStyle = .MediumStyle
            return dateFormatter
        }()
        
    }
    
    static var webAPIDateFormatter : NSDateFormatter {
        return StaticVariables.userFriendlyFormatter
    }
    
}