//
//  Camera.swift
//  vql
//
//  Created by len on 2015/11/8.
//  Copyright © 2015年 len. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

class MyCamera
{
    func isCameraAvailable() -> Bool{
        return UIImagePickerController.isSourceTypeAvailable(.Camera)
    }
    
    func cameraSupportsMedia(mediaType: String,
        sourceType: UIImagePickerControllerSourceType) -> Bool{
            
            let availableMediaTypes =
            UIImagePickerController.availableMediaTypesForSourceType(sourceType)
            
            if let types = availableMediaTypes{
                for type in types{
                    if type == mediaType{
                        return true
                    }
                }
            }
            
            return false
    }
    
    func doesCameraSupportTakingPhotos() -> Bool{
        // kUTTypeImage belong to lib MobileCoreServices
        return cameraSupportsMedia(kUTTypeImage as String, sourceType: .Camera)
    }
}