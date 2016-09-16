//
//  SegueHandlerType.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/08/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

protocol SegueHandlerType {
    
    associatedtype SegueIdentifier: RawRepresentable
}

extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    
    func segueIdentifierForSegue(_ segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) else { fatalError("Unknown segue: \(segue)") }
        return segueIdentifier
    }
    
    func performSegue(_ segueIdentifier: SegueIdentifier) {
        performSegue(segueIdentifier, sender: nil)
    }
    
    func performSegue(_ segueIdentifier: SegueIdentifier, sender: AnyObject?) {
        performSegue(withIdentifier: segueIdentifier.rawValue, sender: sender)
    }
}
