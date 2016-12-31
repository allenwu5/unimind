//
//  PhotoThumbnail.swift
//  album
//
//  Created by len on 2016/12/26.
//  Copyright © 2016年 unimind. All rights reserved.
//

import UIKit

class PhotoThumbnail: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    
    func setThumbnailImage(thumbnailImage: UIImage)
    {
        self.imgView.image = thumbnailImage
    }
}
