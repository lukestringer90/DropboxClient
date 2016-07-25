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
            for view in loadginOutlets { view.hidden = !isUploading }
            uploadButton.hidden = isUploading
        }
    }
    
    var basePath: String?
    
    // MARK: Outlets
    
    @IBOutlet var loadginOutlets: [UIView]!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var chooseFolderButton: UIButton!
    
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
    
    // MARK: Actions
    
    @IBAction func uploadTapped(sender: AnyObject) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func dismissToUpload(segue: UIStoryboardSegue) {
        let folderVC = segue.sourceViewController as! FolderViewController
        basePath = folderVC.folder.path
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print("Cancelled image pick")
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            print("Failed to get picked image")
            return
        }
        
        guard let imageData = UIImagePNGRepresentation(image) else {
            print("Cannot make data")
            return
        }
        
        let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        let filename = self.uploadPathForImageAtReferenceURL(imageURL)
        
        uploadImageData(imageData, path: filename)
    }
    
    // MARK: Dropbox
    
    func uploadImageData(imageData: NSData, path: String) {
        self.isUploading = true
        
        let client = Dropbox.authorizedClient!
        client.files.upload(path: path, input: imageData).response({ (uploadResponse, uploadError) in
            if let uploadName = uploadResponse?.name, uploadRevision = uploadResponse?.rev {
                print("*** Upload file ****")
                print("Uploaded file name: \(uploadName)")
                print("Uploaded file revision: \(uploadRevision)")
                
                self.isUploading = false
                
                client.files.getMetadata(path: path).response({ (response, metaDataError) in
                    if let metaData = response {
                        if let file = metaData as? Files.FileMetadata {
                            print("This is a file with path: \(file.pathLower)")
                            print("File size: \(file.size)")
                        } else if let folder = metaData as? Files.FolderMetadata {
                            print("This is a folder with path: \(folder.pathLower)")
                        }
                    }
                    else {
                        print(metaDataError!)
                    }
                })
            }
            else {
                print(uploadError!)
            }
        })
    }
    
    func uploadPathForImageAtReferenceURL(referenceURL: NSURL) -> String {
        guard let path = basePath else {
            fatalError("Must have a base path for image")
        }
        
        let result = PHAsset.fetchAssetsWithALAssetURLs([referenceURL], options: nil)
        let asset = result.firstObject as! PHAsset
        return "\(path)/Photo \(dateFormatter.stringFromDate(asset.creationDate!)).png"
    }
}

