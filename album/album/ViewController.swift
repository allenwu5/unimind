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

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var collectionView: UICollectionView!

    var albumFound: Bool = false
    var assetCollection: PHAssetCollection!
    var photoAsset: PHFetchResult<PHAsset>!
    
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
        self.photoAsset = PHAsset.fetchAssets(in: self.assetCollection, options: nil)
        
        
        self.collectionView.reloadData()
    }

    @IBAction func btnCamera(_ sender: Any) {
    }
    
    @IBAction func btnPhotoAlbum(_ sender: Any) {
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
            controller.assetCollection = self.assetCollection
            controller.photoAsset = self.photoAsset
            
        }
    }

    // Type 'ViewController' does not conform to protocol 'UICollectionViewDataSource'
    @available(iOS 6.0, *)
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        var count:Int = 0
        if (self.photoAsset != nil)
        {
            count = self.photoAsset.count;
        }
        return count;
    }
    
    @available(iOS 6.0, *)
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell: PhotoThumbnail = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoThumbnail

        let asset: PHAsset = self.photoAsset[indexPath.item]
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil, resultHandler: {
            (result: UIImage?, info:[AnyHashable: Any]?)in
            cell.setThumbnailImage(thumbnailImage: result!)
        })
        
        return cell
    }
}

