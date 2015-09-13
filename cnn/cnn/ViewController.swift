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
        
        println("Start==============================")
        
        println("Minist reading==============================")
        let mnist = Mnist()
        let pixels:[UInt8] = mnist.read()
        var inputs = [Float]()
        
        let testImgNum = 1;
        
        let imgSize = 28,   imgArea   = imgSize   * imgSize
        let inputSize = 29, inputArea = inputSize * inputSize
        
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
        var desiredOutput = [Float](count: 10, repeatedValue: 0.0)
        // desired........
        desiredOutput[5] = 1
        
        println("NN init==============================")
        let rhwd = RecognizeHandWrittenDigits()
        rhwd.initNN()
        
        var eta:Float = 0.005
        
        println("NN BP==============================")
        for (var i = 0; i < 10; ++i)
        {
            rhwd.NN.backPropagate(&outputs, desiredOutput: &desiredOutput, eta: eta)
            rhwd.NN.forward(inputs, output: &outputs)
            printOutputs(outputs)
        }

        println("NN FW==============================")
        rhwd.NN.forward(inputs, output: &outputs)
        printOutputs(outputs)
        
        println("Done==============================")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func printOutputs(outputs:[Float])
    {
        var idx = 0
        for n in outputs
        {
            println("\(idx++): \(n)")
        }
    }
}

