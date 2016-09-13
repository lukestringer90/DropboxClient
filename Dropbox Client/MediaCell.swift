//
//  MediaCell.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 11/09/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit

class MediaCell: UITableViewCell {

    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var thumnailView: UIImageView?
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var percentageLabel: UILabel?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        filenameLabel.text = nil
        descriptionLabel?.text = nil
        thumnailView?.image = nil
        progressView?.progress = 0
        percentageLabel?.text = nil
    }
    
}
