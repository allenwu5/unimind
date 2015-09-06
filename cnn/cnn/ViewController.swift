//
//  ViewController.swift
//  cnn
//
//  Created by len on 2015/9/2.
//  Copyright (c) 2015年 len. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("Start==============================")
        let mnist = Mnist()
        let pixels:[UInt8] = mnist.read()
        var inputs = [Float]()
        
        let testImgNum = 5;
        
        let imgSize = 28
        let imgArea = imgSize * imgSize
        let inputSize = 29
        let inputArea = inputSize * inputSize
        
        for (var i = 0; i < testImgNum; ++i)
        {
            for (var j = 0; j < imgArea; ++j)
            {
                let idx = (i * imgArea) + j
                inputs.append(Float(pixels[idx]))
            }
            for (var a = 0; a < inputArea - imgArea; ++a)
            {
                inputs.append(0.0)
            }
        }
        assert(inputs.count == testImgNum * inputArea)
        
        // 10 outpus for 0 ~ 9
        var outputs = [Float](count: 10, repeatedValue: 0.0)
        
        let rhwd = RecognizeHandWrittenDigits()
        rhwd.initNN()
        rhwd.NN.forward(inputs, output: outputs)
        print("Done==============================")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

