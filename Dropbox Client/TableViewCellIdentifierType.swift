//
//  TableViewCellIdentifierType.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/08/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

protocol TableViewCellIdentifierType {
    
    associatedtype TableViewCellIdentifier: RawRepresentable
}

extension TableViewCellIdentifierType where Self: UITableViewController, TableViewCellIdentifier.RawValue == String {
    
    func dequeCell(_ identifier: TableViewCellIdentifier) -> UITableViewCell {
        guard let tv = self.tableView else {
            fatalError("No table view")
        }
        
        guard let cell = tv.dequeueReusableCell(withIdentifier: identifier.rawValue) else {
            fatalError("No cell to deque for with ID: \(identifier.rawValue)")
        }
        
        return cell
    }
    
    func dequeCell(_ identifier: TableViewCellIdentifier, indexPath: IndexPath) -> UITableViewCell {
        guard let tv = self.tableView else {
            fatalError("No table view")
        }
        
        return tv.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
    }
}
