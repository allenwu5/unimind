//
//  PhotoMetaInfo.swift
//  album
//
//  Created by len on 2017/8/30.
//  Copyright © 2017年 unimind. All rights reserved.
//

import UIKit
import os.log

class PhotoInfo: NSObject, NSCoding {
    
    //MARK: Properties
    
    var name: String
    var rating: Int
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("photo_info")
    
    //MARK: Types
    
    struct PropertyKey {
        static let name = "name"
        static let rating = "rating"
    }
    
    //MARK: Initialization
    
    init?(name: String, rating: Int) {
        
        // The name must not be empty
        guard !name.isEmpty else {
            return nil
        }
        
        // The rating must be between 0 and 5 inclusively
        guard (rating >= 0) && (rating <= 5) else {
            return nil
        }
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty || rating < 0  {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.rating = rating
        
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(rating, forKey: PropertyKey.rating)
    }
    
    //The required modifier means this initializer must be implemented on every subclass, if the subclass defines its own initializers.
    //The convenience modifier means that this is a secondary initializer, and that it must call a designated initializer from the same class.
    //The question mark (?) means that this is a failable initializer that might return nil.
    required convenience init?(coder aDecoder: NSCoder) {
        
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name for a PhotoInfo object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let rating = aDecoder.decodeInteger(forKey: PropertyKey.rating)
        
        // Must call designated initializer.
        self.init(name: name, rating: rating)
        
    }
}
