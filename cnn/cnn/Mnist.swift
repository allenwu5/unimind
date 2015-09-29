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

    let iLen32 = sizeof(UInt32)
    let iLen8  = sizeof(UInt8)

    var iInstances = [MnistInstance]()

    init ()
    {
        p16_2 = p16_1 * p16_1
        p16_3 = p16_2 * p16_1
    }

    func read(aTestCount:Int)
    {
        readTrainImages(aTestCount)
        readTrainLabels()

        for i:MnistInstance in iInstances
        {
            i.printImage()
        }
    }
    
    func convertDigit(array:[UInt8])->Int
    {
        return Int(UInt32(array[0]) * p16_3 + UInt32(array[1]) * p16_2 + UInt32(array[2]) * p16_1 + UInt32(array[3]))
    }
    
    func readTrainImages(aTestCount:Int)
    {
        let trainImgFile   = "MNIST/train-images-idx3-ubyte"
        
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

            // Read 4 attributes
            var offset = 0

            var buffer = [UInt8](count: iLen32, repeatedValue: 0)
            data.getBytes(&buffer, range: NSMakeRange(offset, iLen32))
            offset += iLen32
            let magicNum = convertDigit(buffer)

            data.getBytes(&buffer, range: NSMakeRange(offset, iLen32))
            offset += iLen32
            let imgNum = convertDigit(buffer)

            data.getBytes(&buffer, range: NSMakeRange(offset, iLen32))
            offset += iLen32
            let rowNum = convertDigit(buffer)

            data.getBytes(&buffer, range: NSMakeRange(offset, iLen32))
            offset += iLen32
            let colNum = convertDigit(buffer)

            for (var i = 0; i < aTestCount; ++i)
            {
                let ins = MnistInstance()

                ins.iHeight = rowNum
                ins.iWidth = colNum

                let bytes = ins.getArea() * iLen8
                ins.iImage = [UInt8](count: bytes, repeatedValue: 0)

                data.getBytes(&(ins.iImage), range: NSMakeRange(offset, bytes))
                offset += bytes;

                iInstances.append(ins)
            }

            print("error: \(error)")
        }
    }

    func readTrainLabels()
    {
        let trainLabelFile = "MNIST/train-labels-idx1-ubyte"
//        [offset] [type]          [value]          [description]
//        0000     32 bit integer  0x00000801(2049) magic number (MSB first)
//        0004     32 bit integer  60000            number of items
//        0008     unsigned byte   ??               label
//        0009     unsigned byte   ??               label
//            ........
//            xxxx     unsigned byte   ??               label

        if let path = NSBundle.mainBundle().pathForResource(trainLabelFile, ofType:"") {
            var error:NSError?
            //            let s = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: &error)
            let data = NSData(contentsOfFile: path)!

            var offset = 0

            var buffer = [UInt8](count: iLen32, repeatedValue: 0)
            data.getBytes(&buffer, range: NSMakeRange(offset, iLen32))
            offset += iLen32
            let magicNum = convertDigit(buffer)


            data.getBytes(&buffer, range: NSMakeRange(offset, iLen32))
            offset += iLen32
            let imgNum = convertDigit(buffer)


            for i in iInstances
            {
                var label = UInt8()
                data.getBytes(&label, range: NSMakeRange(offset, iLen8))
                i.iLabel = Int(label)
                offset += iLen8;
            }
            print("error: \(error)")
        }
    }
}

class MnistInstance
{
    var iImage = [UInt8]()
    var iLabel = -1
    var iHeight = 0
    var iWidth = 0

    func getArea() -> Int
    {
        return iHeight * iWidth
    }

    func printImage()
    {
        print("Label: \(iLabel)")
        for (var r = 0; r < iHeight; ++r)
        {
            for (var c = 0; c < iWidth; ++c)
            {
                let s = iImage[r * iWidth + c] > 0 ? "*" : " "
                print(" \(s)", terminator: "")
            }
            print("")
        }
        print("----------------------------------------------")
    }

    func copyImageToNNInput(aNNInputLen:Int, aNNInputArea:Int) -> [Float]
    {
        // 1 is white, -1 is black
        var nnInput = [Float](count: aNNInputArea, repeatedValue: -1.0)

        for (var ii = 0; ii < iHeight; ++ii)
        {
            for (var jj = 0; jj < iWidth; ++jj)
            {
                let v = (Float)(iImage[ jj + iWidth*ii ])/128.0 - 1.0
                //print(v)
                nnInput[ (1 + jj) + aNNInputLen * (ii + 1) ] = v;
            }
        }

        //
//        for (var r = 0; r < iHeight; ++r)
//        {
//            for (var c = 0; c < iWidth; ++c)
//            {
//                let s = nnInput[r * iWidth + c] > 0 ? "x" : " "
//                print(" \(s)", terminator: "")
//            }
//            print("")
//        }
//        print("----------------------------------------------")

        return nnInput
    }
}