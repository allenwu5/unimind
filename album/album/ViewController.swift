//
//  ViewController.swift
//  album
//
//  Created by len on 2016/12/10.
//  Copyright © 2016年 unimind. All rights reserved.
//

import UIKit
import Photos // from Photos.framework

let reuseIdentifier = "PhotoCell"
let albumName = "My App"

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!

    var albumFound: Bool = false
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult<PHAsset>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if the folder exists, if not, create it
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if (collection.firstObject != nil)
        {
            self.albumFound = true
            self.assetCollection = collection.firstObject!
        }
        else
        {
            // Folder "My App" does not exist
            // Creating now...
            NSLog("\nFolder \"%@\" does not exist\nCreating now...", albumName)
            PHPhotoLibrary.shared().performChanges({
                _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                
            }, completionHandler: {(success:Bool, error: Error?)in
                let s:String = success ? "Success" : "Error!"
                NSLog("Creation of folder  \(s)")
                self.albumFound = success
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.hidesBarsOnTap = false
        // Fetch the photos from collection
        self.photosAsset = PHAsset.fetchAssets(in: self.assetCollection, options: nil)
        
        
        self.collectionView.reloadData()
    }

    @IBAction func btnCamera(_ sender: Any) {
        if (UIImagePickerController.isSourceTypeAvailable(.camera))
        {
            //load the camera interface
            let picker : UIImagePickerController = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = false
            self.present(picker, animated: true, completion: nil)
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "No camera available", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnPhotoAlbum(_ sender: Any) {
        let picker : UIImagePickerController = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = false
        self.present(picker, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier! == "viewLargePhoto")
        {
            let controller:ViewPhoto = segue.destination as! ViewPhoto
            let indexPath:IndexPath = self.collectionView.indexPath(for: sender as! UICollectionViewCell)!
            
            controller.index = indexPath.item
            controller.photosAsset = self.photosAsset
            controller.assetCollection = self.assetCollection
        }
    }

    // Type 'ViewController' does not conform to protocol 'UICollectionViewDataSource'
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        var count:Int = 0
        if (self.photosAsset != nil)
        {
            count = self.photosAsset.count;
        }
        return count;
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell: PhotoThumbnail = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoThumbnail

        let asset: PHAsset = self.photosAsset[indexPath.item]
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil, resultHandler: {
            (result: UIImage?, info:[AnyHashable: Any]?)in
            cell.setThumbnailImage(thumbnailImage: result!)
        })
        
        return cell
    }
    
    // UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return 1
    }
    
    // UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        let image = info["UIImagePickerControllerOriginalImage"] as! UIImage
        
        PHPhotoLibrary.shared().performChanges({
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection, assets: self.photosAsset)
            albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration )
        }, completionHandler: {(success, error)in
            NSLog("Adding image to library -> %@", (success ? "Success" : "Error"))
            picker.dismiss(animated: true, completion: nil)
        })
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
}

