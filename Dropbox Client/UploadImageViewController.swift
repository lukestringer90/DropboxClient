//
//  ViewController.swift
//  Dropbox Client
//
//  Created by Luke Stringer on 24/07/2016.
//  Copyright © 2016 Luke Stringer. All rights reserved.
//

import UIKit
import SwiftyDropbox
import Photos

class UploadImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let dateFormatter = NSDateFormatter()
    let imagePicker = UIImagePickerController()
    
    var isUploading = false {
        didSet {
            for view in buttons { view.enabled = !isUploading }
            uploadingLabel.hidden = !isUploading
            progressView.hidden = !isUploading
        }
    }
    
    var basePath: String? {
        didSet {
            folderLabel.text = basePath?.characters.count > 0 ? basePath : "/"
        }
    }
    
    var imageName: String? {
        didSet {
            imageLabel.text = imageName
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var uploadingLabel: UILabel!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var folderLabel: UILabel!
    @IBOutlet weak var imageLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Format used to generate file name, which should not contain / chars
        dateFormatter.dateFormat = "dd-MM-yyyy, hh mm ss"
        
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        
        isUploading = false
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if Dropbox.authorizedClient == nil {
            Dropbox.authorizeFromController(self)
        }
        
    }
    
    func showAlertText(text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @IBAction func chooseImageTapped(sender: AnyObject) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func dismissToUploadWithFolder(segue: UIStoryboardSegue) {
        let folderVC = segue.sourceViewController as! FolderViewController
        basePath = folderVC.folder.path
    }
    
    @IBAction func dismissToUpload(segue: UIStoryboardSegue) {
    }
    
    @IBAction func uploadTapped(sender: AnyObject) {
        guard let image = imageView.image else {
            showAlertText("No image")
            return
        }
        
        guard let imageData = UIImagePNGRepresentation(image) else {
            showAlertText("Cannot make image data")
            return
        }
        
        guard let basePath = basePath else {
            showAlertText("No folder set")
            return
        }
        
        uploadImageData(imageData, path: "\(basePath)/\(imageName)")
    }
    
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print("Cancelled image pick")
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            showAlertText("Failed to get picked image")
            return
        }
        
        imageView.image = image
        
        let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        imageName = self.nameForImageAtReferenceURL(imageURL)
    }
    
    // MARK: Dropbox
    
    func uploadImageData(imageData: NSData, path: String) {
        self.isUploading = true
        
        let client = Dropbox.authorizedClient!
        let request = client.files.upload(path: path, input: imageData)
        
        request.response({ (_, uploadError) in
            if let error = uploadError {
                dispatch_async(dispatch_get_main_queue(), {
                    self.showAlertText(error.description)
                })
            }
            
            self.isUploading = false
        })
        
        request.progress { (_, current, total) in
            let progress: Float = Float(current) / Float(total)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.progressView.progress = progress
            })
        }
    }
    
    func nameForImageAtReferenceURL(referenceURL: NSURL) -> String {
        let result = PHAsset.fetchAssetsWithALAssetURLs([referenceURL], options: nil)
        let asset = result.firstObject as! PHAsset
        return "Photo \(dateFormatter.stringFromDate(asset.creationDate!)).png"
    }
}

