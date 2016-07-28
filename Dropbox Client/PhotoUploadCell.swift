//
//  PhotoUploadCell.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
class PhotoUploadCell: UITableViewCell {
    
    static func cellIDForState(state: UploadState) -> String {
        return "\(state.rawValue.capitalizedString)CellID"
    }

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var photoDetailLabel: UILabel?
    @IBOutlet weak var progressView: UIProgressView?
    
}
