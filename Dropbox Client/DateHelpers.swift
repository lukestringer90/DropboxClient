//
//  DateHelpers.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 11/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import Foundation

extension Date {
    func userFriendlyString() -> String? {
        return DateFormatter.webAPIDateFormatter.string(from: self)
    }
}

extension DateFormatter {
    
    fileprivate struct StaticVariables {
        
        static let userFriendlyFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .medium
            return dateFormatter
        }()
        
    }
    
    static var webAPIDateFormatter : DateFormatter {
        return StaticVariables.userFriendlyFormatter
    }
    
}
