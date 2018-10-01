//
//  ViewController.swift
//  album
//
//  Created by len on 2016/12/10.
//  Copyright © 2016年 unimind. All rights reserved.
//

import UIKit
import Photos // from Photos.framework
import CoreML

let reuseIdentifier = "PhotoCell"
let albumName = "My App"
var model_inceptionv3: Inceptionv3!
let imageWidth = 299

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!

    var albumFound: Bool = false
    var assetCollection: PHAssetCollection!
    var photosAsset: PHFetchResult<PHAsset>!
    
    @IBOutlet weak var photoClass: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if the folder exists, if not, create it
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        
        var collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if (collection.firstObject == nil)
        {
            // Folder "My App" does not exist, create it
            do {
                try PHPhotoLibrary.shared().performChangesAndWait({
                    NSLog("\nFolder \"%@\" does not exist\nCreating now...", albumName)
                    _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                })
            }
            catch let error {
                print("Creating album error: \(error)")
            }

            collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        }
        self.albumFound = true
        self.assetCollection = collection.firstObject!
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.hidesBarsOnTap = false
        // Fetch the photos from collection
        self.photosAsset = PHAsset.fetchAssets(in: self.assetCollection, options: nil)
        
        self.collectionView.reloadData()
        
        // Why initialization here would be faster than in viewDidLoad
        model_inceptionv3 = Inceptionv3()
    }

    @IBAction func btnPlay(_ sender: Any) {
        var photoInfos = [PhotoInfo]()
        for i in 0 ..< self.photosAsset.count
        {
            let asset: PHAsset = self.photosAsset[i]
//            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil, resultHandler: {
//                (result: UIImage?, info:[AnyHashable: Any]?)in
//                //cell.setThumbnailImage(thumbnailImage: result!)
//                print("btnPlay")
//                
//            })
            
//            print(asset.location!)
            PHImageManager.default().requestImageData(for: asset, options: nil) {
                photoData, photoUTI, photoOrientation, photoInfo in
                
                let selectedImageSourceRef = CGImageSourceCreateWithData(photoData! as CFData, nil)!
                let imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(selectedImageSourceRef, 0, nil)!

                if let theJSONData = try? JSONSerialization.data(
                    withJSONObject: imagePropertiesDictionary,
                    options: []) {
                        let theJSONText = String(data: theJSONData,
                                                 encoding: .ascii)
                    
                    NSLog(theJSONText!)
                    self.photoClass.text = theJSONText
                }

                if let dict = imagePropertiesDictionary as? [String: AnyObject] {
                    if let tiff = dict["{TIFF}"]
                    {
                        if let dateTime:String = tiff["DateTime"] as? String {
                            let photoInfo = PhotoInfo(name: dateTime, rating: 4)
                            photoInfos.append(photoInfo!)
                            
                            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(photoInfos, toFile: PhotoInfo.ArchiveURL.path)
                        }
                    }
                    
                    if let exif = dict["{Exif}"]
                    {
                        if let dateTime:String = exif["DateTimeOriginal"] as? String {
                            let photoInfo = PhotoInfo(name: dateTime, rating: 4)
                            photoInfos.append(photoInfo!)
                            
                            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(photoInfos, toFile: PhotoInfo.ArchiveURL.path)
                        }
                    }
                }
            }
        }
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
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil, resultHandler: {
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
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
//        PHPhotoLibrary.shared().performChanges({
//            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
//            let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
//            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection, assets: self.photosAsset)
//            albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration )
//        }, completionHandler: {(success, error)in
//            NSLog("Adding image to library -> %@", (success ? "Success" : "Error"))
//            picker.dismiss(animated: true, completion: nil)
//        })
        
        // Start of https://www.appcoda.com.tw/coreml-introduction/
        NSLog("Analyzing Image...")
        
        // Change size and exporting as newImage
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageWidth, height: imageWidth), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // CVPixelBuffer
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        // CGContext
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // Draw new one and removing old one ?
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        // imageView.image = newImage
        
        // Using Core ML
        guard let prediction = try? model_inceptionv3.prediction(image: pixelBuffer!) else {
            return
        }
        
        let strPhotoClass = "It looks like ... \(prediction.classLabel)."
        NSLog(strPhotoClass)
        photoClass.text = strPhotoClass
        
        picker.dismiss(animated: true, completion: nil)
        // End of https://www.appcoda.com.tw/coreml-introduction/
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
}

