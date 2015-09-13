//
//  Mnist.swift
//  vql
//
//  Created by len on 2015/8/31.
//  Copyright (c) 2015年 len. All rights reserved.
//

import Foundation

class Mnist
{
    let p16_1:UInt32 = 16 * 16
    let p16_2:UInt32
    let p16_3:UInt32

    init ()
    {
        p16_2 = p16_1 * p16_1
        p16_3 = p16_2 * p16_1
    }
    
    func convertDigit(array:[UInt8])->Int
    {
        return Int(UInt32(array[0]) * p16_3 + UInt32(array[1]) * p16_2 + UInt32(array[2]) * p16_1 + UInt32(array[3]))
    }
    
    func read() -> [UInt8]
    {
        let trainImgFile   = "MNIST/train-images-idx3-ubyte"
        let trainLabelFile = "MNIST/train-labels-idx1-ubyte"
        
        //        TRAINING SET IMAGE FILE (train-images-idx3-ubyte):
        //
        //        [offset] [type]          [value]          [description]
        //        0000     32 bit integer  0x00000803(2051) magic number
        //        0004     32 bit integer  60000            number of images
        //        0008     32 bit integer  28               number of rows
        //        0012     32 bit integer  28               number of columns
        //        0016     unsigned byte   ??               pixel
        //        0017     unsigned byte   ??               pixel
        //        ........
        //        xxxx     unsigned byte   ??               pixel
        
        if let path = NSBundle.mainBundle().pathForResource(trainImgFile, ofType:"") {
            var error:NSError?
            //            let s = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)
            let data = NSData(contentsOfFile: path)!
            
            let len32 = sizeof(UInt32)
            
            var buffer = [UInt8](count: len32, repeatedValue: 0)
            data.getBytes(&buffer, range: NSMakeRange(0, len32))
            let magicNum = convertDigit(buffer)
            data.getBytes(&buffer, range: NSMakeRange(len32, len32))
            let imgNum = convertDigit(buffer)
            data.getBytes(&buffer, range: NSMakeRange(len32 * 2, len32))
            let rowNum = convertDigit(buffer)
            data.getBytes(&buffer, range: NSMakeRange(len32 * 3, len32))
            let colNum = convertDigit(buffer)
            
            // the number of elements:
            let count = (data.length - (len32 * 4)) / sizeof(UInt8)
            
            
            // create array of appropriate length:
            var pixels = [UInt8](count: count, repeatedValue: 0)
            
            // copy bytes into array
            data.getBytes(&pixels, range: NSMakeRange(len32 * 4, count))
            
            var img = [[UInt8]](count:rowNum, repeatedValue:[UInt8](count:colNum, repeatedValue:0))
            var idx = 0;
            
            let testImgNum = 5;
            for (var i = 0; i < testImgNum; ++i)
            {
                for (var r = 0; r < rowNum; ++r)
                {
                    for (var c = 0; c < colNum; ++c)
                    {
                        img[r][c] = pixels[idx++]
                    }
                }
                
                for (var r = 0; r < rowNum; ++r)
                {
                    for (var c = 0; c < colNum; ++c)
                    {
                        let b = img[r][c] > 0 ? "*" : " "
                        print(" \(b)")
                    }
                    println();
                }
            }
            
            println("error: \(error)")
            return pixels
        }
        return [UInt8]()
    }
}