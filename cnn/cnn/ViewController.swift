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

        print("Minist reading==============================")
        let mnist = Mnist()
        mnist.read(20)


        print("NN init==============================")
        let rhwd = RecognizeDigits()
        rhwd.initNN()

        // learning rate
        let eta:Float = 0.01
        let iterations = 2


        for (var t = 0; t < 5; ++t)
        {
            for ins in mnist.iInstances
            {
                let nnInput:[Float] = ins.copyImageToNNInput(rhwd.iInputLen, aNNInputArea: rhwd.iInputArea)

                // 10 outpus for 0 ~ 9

                var desiredOutput = [Float](count: 10, repeatedValue: -1)
                desiredOutput[ins.iLabel] = 1

                print("NN Iteration for label: \(ins.iLabel)==============================")

                for (var i = 0; i < iterations; ++i)
                {
                    print(">", terminator:" ")
                    let output = rhwd.NN.forward(nnInput)

                    print("<", terminator:" ")
                    rhwd.NN.backPropagate(output, desiredOutput: desiredOutput, eta: eta)

                    printOutputIndex(output)

                }
                print("")

            }
        }

        print("NN Recall==============================")


        var penalty = 0
        for ins in mnist.iInstances
        {
            // *
            // * NO INPUT
            // *
            let nnInput:[Float] = ins.copyImageToNNInput(rhwd.iInputLen, aNNInputArea: rhwd.iInputArea)

            print("NN FW for label: \(ins.iLabel)==============================")
            let output = rhwd.NN.forward(nnInput)
            let result = printOutputIndex(output)
            penalty += ins.iLabel == result ? 0 : 1
        }

        print("Done==============================")
        print("Penalty: \(penalty) / \(mnist.iInstances.count)")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func printOutput(aOutput:[Float])
    {
        var idx = 0
        for n in aOutput
        {
            print("\(idx++): \(n + 2)")
        }
    }
    
    func printOutputIndex(aOutput:[Float]) -> Int
    {
        var idx = -1
        var max:Float = 0.0
        for (var i = 0; i < aOutput.count; ++i)
        {
            if (idx == -1 || aOutput[i] >= max)
            {
                idx = i
                max = aOutput[i]
            }
        }
        print("index: \(idx)")
        return idx
    }
}

