//
//  File.swift
//  cnn
//
//  Created by len on 2015/12/1.
//  Copyright © 2015年 len. All rights reserved.
//

import Foundation

class Train
{
    // learning rate
    let eta:Double = 0.01
    let epochs = 5 // 10 ~ 20
    
    let io = IO()
    
    func run(mnist:Mnist, rhwd:RecognizeDigits)
    {    
        for (var l = 0; l < epochs; l += 1)
        {
            var penalty = 0
            for ins in mnist.iTrainInstances
            {
                let nnInput:[Double] = ins.copyImageToNNInput(rhwd.iInputLen, aNNInputArea: rhwd.iInputArea)
                
                // 10 outpus for 0 ~ 9
                
                var desiredOutput = [Double](count: 10, repeatedValue: -1)
                desiredOutput[ins.iLabel] = 1
                
                //print("NN Iteration for label: \(ins.iLabel)==============================")
                
                if (true)
                {
                    //print(">", terminator:" ")
                    let output = rhwd.NN.forward(nnInput)
                    let outputLabel = io.getOutputLabel(output)
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
    }
}