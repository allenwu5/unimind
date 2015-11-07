//
//  ViewController.swift
//  cnn
//
//  Created by len on 2015/9/2.
//  Copyright (c) 2015年 len. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let useCache = true
    
    // learning rate
    let eta:Double = 0.01
    let trainCases = 6000 // 60000
    let testCases = 1000 // 10000

    let epochs = 20 // 10 ~ 20

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

        for (var l = 0; !useCache && l < epochs; ++l)
        {
            var penalty = 0
            for ins in mnist.iTrainInstances
            {
                let nnInput:[Double] = ins.copyImageToNNInput(rhwd.iInputLen, aNNInputArea: rhwd.iInputArea)

                // 10 outpus for 0 ~ 9

                var desiredOutput = [Double](count: 10, repeatedValue: -1)
                desiredOutput[ins.iLabel] = 1

                print("NN Iteration for label: \(ins.iLabel)==============================")

                if (true)
                {
                    //print(">", terminator:" ")
                    let output = rhwd.NN.forward(nnInput)
                    let outputLabel = getOutputLabel(output)
                    //print(getOutputLabel(output))
                    
                    penalty += ins.iLabel == outputLabel ? 0 : 1
                    
                    if (outputLabel != ins.iLabel)
                    {
                        //print("<", terminator:" ")
                        rhwd.NN.backPropagate(output, desiredOutput: desiredOutput, eta: eta)
                    }
                }
                //print("")
            }
            
            print("Epoch \(l + 1) done \(NSDate())")
            
            if (penalty == 0)
            {
                break
            }
        }

        if (useCache)
        {
            rhwd.NN.loadFromFile()
        }
        else
        {
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
            let outputLabel = getOutputLabel(output)
            
            if (ins.iLabel != outputLabel)
            {
                print("NN FW for label: \(ins.iLabel)==============================")
                print(outputLabel)

                ++penalty
                ins.printImage()
            }
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
    
    final func getOutputLabel(aOutput:[Double]) -> Int
    {
        var idx = -1
        var max:Double = 0.0
        for (var i = 0; i < aOutput.count; ++i)
        {
            if (idx == -1 || aOutput[i] >= max)
            {
                idx = i
                max = aOutput[i]
            }
        }
        return idx
    }
}

