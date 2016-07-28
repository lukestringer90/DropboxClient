//
//  PhotoUploadCell.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 28/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

enum UploadState: String {
    case Waiting
    case Uploading
    case Uploaded
    
    func cellID() -> String {
        return "\(rawValue)CellID"
    }
}

class PhotoUploadCell: UITableViewCell {
    
    static let loadingCellID = "LoadingCellID"

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var photoDetailLabel: UILabel?
    @IBOutlet weak var progressView: UIProgressView?
    
}
