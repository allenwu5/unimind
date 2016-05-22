//
//  ViewController.swift
//  cnn
//
//  Created by len on 2015/9/2.
//  Copyright (c) 2015年 len. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let useCache = false
    let useTheanoWeight = false
    

    let trainCases = 10000 // 60000
    let testCases = 100 // 10000

    let io = IO()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.

        print("Start============================== \(NSDate())")

        print("Minist reading==============================")
        let mnist = Mnist()
        mnist.read(trainCases, aTestCount: testCases)

        print("NN init==============================")
        let rhwd = RecognizeDigits()
        rhwd.initNN()

        if (useCache)
        {
            let result = (useTheanoWeight && rhwd.NN.loadFromTheano()) || rhwd.NN.loadFromFile()
            if (!result)
            {
                print("Cannot load cache")
                return;
            }
        }
        else
        {   
            let train = Train()
            train.run(mnist, rhwd: rhwd)
            rhwd.NN.saveToFile()
        }
        
        print("NN Recall============================== \(NSDate())")


        var penalty = 0
        var total = 0
        for ins in mnist.iTestInstances
        {
            // *
            // * NO INPUT
            // *
            let nnInput:[Double] = ins.copyImageToNNInput(rhwd.iInputLen, aNNInputArea: rhwd.iInputArea)

            
            let output = rhwd.NN.forward(nnInput)
            let outputLabel = io.getOutputLabel(output)
            
            print("NN FW for label: \(ins.iLabel)==============================")
            if (ins.iLabel != outputLabel)
            {
                
                print(outputLabel)

                ++penalty
                
            }
//            ins.printImage()
            ++total
        }

        print("Done============================== \(NSDate())")
        print("Penalty: \(penalty) / \(total)")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    final func printOutput(aOutput:[Double])
    {
        var idx = 0
        for n in aOutput
        {
            print("\(idx++): \(n)")
        }
    }
    

}

