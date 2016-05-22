//
//  Cnn.swift
//  vql
//
//  Created by len on 2015/7/25.
//  Copyright (c) 2015年 len. All rights reserved.
//

import Foundation


class RecognizeDigits
{
    let ULONG_MAX:Int = 65535
    let iInputLen = 29
    let iInputArea:Int

    let NN = NeuralNetwork()  // for easier nomenclature

    init ()
    {
        iInputArea = iInputLen * iInputLen
    }
    func initNN()
    {
        // initialize and build the neural net
        
        
        // NN.initialize()
        
        // layer zero, the input layer.
        // Create neurons: exactly the same number of neurons as the input
        // vector of 29x29=841 pixels, and no weights/connections

        
        let pLayer0 = Layer(label:"Layer00")
        NN.layers.append(pLayer0)
        
        for (var ii=0; ii<iInputArea; ++ii )
        {
            pLayer0.neurons.append(Neuron())
        }
        
        // layer one:
        // This layer is a convolutional layer that
        // has 6 feature maps.  Each feature
        // map is 13x13, and each unit in the
        // feature maps is a 5x5 convolutional kernel
        // of the input layer.
        // So, there are 13x13x6 = 1014 neurons, (5x5+1)x6 = 156 weights
        let featMapCount = 20
        let featMapSize = 12
        let featMapArea = featMapSize * featMapSize
        let kernelSize = 5
        let kernelArea = kernelSize * kernelSize
        let kernelWeightCount = 1 + kernelArea
        
        let neuronCount = featMapCount * featMapArea // feat count times feat map area
        let weightCount = featMapCount * kernelWeightCount // feat count times kernel weight
        

        let pLayer1 = Layer(label:"Layer01",prev: pLayer0)

        NN.layers.append(pLayer1);
        
        for (var ii=0; ii<neuronCount; ++ii )
        {
            pLayer1.neurons.append(Neuron())
        }
        
        for (var ii=0; ii<weightCount; ++ii )
        {
            // uniform random distribution
            pLayer1.weights.append( Weight(value: 0.05 * UNIFORM_PLUS_MINUS_ONE()) )
        }
        
        // interconnections with previous layer: this is difficult
        // The previous layer is a top-down bitmap
        // image that has been padded to size 29x29
        // Each neuron in this layer is connected
        // to a 5x5 kernel in its feature map, which
        // is also a top-down bitmap of size 13x13.
        // We move the kernel by TWO pixels, i.e., we
        // skip every other pixel in the input image
        
        
        var kernelTemplate = [Int]()
        for (var i = 0; i < kernelSize; ++i)
        {
            for (var j = 0; j < kernelSize; ++j)
            {
                kernelTemplate.append(i * iInputLen + j)
            }
        }
        
//        int fm;  // "fm" stands for "feature map"
        
        // 29^2 becomes 20 x 12^2 neurons and 20 x (1 + 5^2) weights
        for (var fm=0; fm<featMapCount; ++fm)//20
        {
            for (var ii=0; ii<featMapSize; ++ii )//12
            {
                for (var jj=0; jj<featMapSize; ++jj )//12
                {
                    // 26 is the number of weights per feature map
                    var iNumWeight:Int = fm * kernelWeightCount;
                    let n = pLayer1.neurons[ jj + ii*featMapSize + fm*featMapArea ]
                    
                    n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ )  // bias weight
                    let move = 2
                    for (var kk=0; kk<kernelArea; ++kk )
                    {
                        // note: max val of index == 840,
                        // corresponding to 841 neurons in prev layer
                        
                        // convolutino here...
                        n.AddConnection( move * (jj + iInputLen * ii) + kernelTemplate[kk], weightIndex: iNumWeight++ );
                    }
                }
            }
        }
        
        // layer two:
        // This layer is a convolutional layer
        // that has 50 feature maps.  Each feature
        // map is 5x5, and each unit in the feature
        // maps is a 5x5 convolutional kernel
        // of corresponding areas of all 6 of the
        // previous layers, each of which is a 13x13 feature map
        // So, there are 5x5x50 = 1250 neurons, (5x5+1)x6x50 = 7800 weights
        
        let l2FeatMapCount = 50
        let l2FeatMapSize = 4
        let l2FeatMapArea = l2FeatMapSize * l2FeatMapSize
        let l2NeuronCount = l2FeatMapCount * l2FeatMapArea
        let l2WeightCount = kernelWeightCount * featMapCount * l2FeatMapCount
        
        
        
        let pLayer2 = Layer(label: "Layer02", prev: pLayer1 );
        NN.layers.append( pLayer2 );
        
        for (var ii=0; ii<l2NeuronCount; ++ii )
        {
            pLayer2.neurons.append(Neuron(label: String(ii)) );
        }
        
        for (var ii=0; ii<l2WeightCount; ++ii )
        {
            pLayer2.weights.append( Weight( value: 0.05 * UNIFORM_PLUS_MINUS_ONE() ) )
        }
        
        // Interconnections with previous layer: this is difficult
        // Each feature map in the previous layer
        // is a top-down bitmap image whose size
        // is 13x13, and there are 6 such feature maps.
        // Each neuron in one 5x5 feature map of this
        // layer is connected to a 5x5 kernel
        // positioned correspondingly in all 6 parent
        // feature maps, and there are individual
        // weights for the six different 5x5 kernels.  As
        // before, we move the kernel by TWO pixels, i.e., we
        // skip every other pixel in the input image.
        // The result is 50 different 5x5 top-down bitmap
        // feature maps
        

        var kernelTemplate2 = [Int]()
        for (var i = 0; i < kernelSize; ++i)
        {
            for (var j = 0; j < kernelSize; ++j)
            {
                kernelTemplate2.append(i * featMapSize + j)
            }
        }
        
        var maxNeuronIndex = 0
        for (var fm=0; fm<l2FeatMapCount; ++fm)
        {
            for (var ii=0; ii<l2FeatMapSize; ++ii )
            {
                for (var jj=0; jj<l2FeatMapSize; ++jj )
                {
                    // 26 is the number of weights per feature map
                    var iNumWeight = fm * kernelWeightCount;
                    let n:Neuron = pLayer2.neurons[ jj + ii*l2FeatMapSize + fm*l2FeatMapArea ]
                    
                    n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ )  // bias weight
                    
                    for (var kk=0; kk<l2FeatMapArea; ++kk )
                    {
                        // note: max val of index == 1013,
                        // corresponding to 1014 neurons in prev layer
                        let move = 2
                        for (var l = 0; l < featMapCount; ++l)
                        {
                            let neuronIndex = (l * featMapArea) + move * (jj + featMapSize * ii) +
                                kernelTemplate2[kk]
                            n.AddConnection(neuronIndex , weightIndex: iNumWeight++ );
                            maxNeuronIndex = max(maxNeuronIndex, neuronIndex)
                        }
                    }
                }
            }
        }
        assert(maxNeuronIndex < neuronCount)
        
        // layer three:
        // This layer is a fully-connected layer
        // with 100 units.  Since it is fully-connected,
        // each of the 100 neurons in the
        // layer is connected to all 1250 neurons in
        // the previous layer.
        // So, there are 100 neurons and 100*(1250+1)=125100 weights
        
        let l3NeuronCount = 500
        let l3WeightCount = l3NeuronCount * (1 + l2NeuronCount) // 500 * (1 + 50 * 4 ^ 2)
        
        let pLayer3 = Layer(label: "Layer03", prev: pLayer2 )
        NN.layers.append( pLayer3 )
        
        for (var ii=0; ii<l3NeuronCount; ++ii )
        {
            pLayer3.neurons.append(Neuron( label: String(ii) ))
        }
        
        for (var ii=0; ii<l3WeightCount; ++ii )
        {
            let initWeight = 0.05 * UNIFORM_PLUS_MINUS_ONE();
            pLayer3.weights.append(  Weight( value: initWeight ) );
        }
        
        // Interconnections with previous layer: fully-connected
        
        var iNumWeight = 0;  // weights are not shared in this layer
        
        for (var fm=0; fm<l3NeuronCount; ++fm )
        {
            let n:Neuron = pLayer3.neurons[ fm ]
            n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ );  // bias weight
            
            for (var ii=0; ii<l2NeuronCount; ++ii ) // // 50 * 4 ^ 2
            {
                n.AddConnection( ii, weightIndex: iNumWeight++ );
            }
        }
        
        // layer four, the final (output) layer:
        // This layer is a fully-connected layer
        // with 10 units.  Since it is fully-connected,
        // each of the 10 neurons in the layer
        // is connected to all 100 neurons in
        // the previous layer.
        // So, there are 10 neurons and 10*(100+1)=1010 weights
        
        let lfNeuronCount = 10
        let lfWeightCount = lfNeuronCount * (1 + l3NeuronCount) // 10 * (1 + 500)
        
        let pLayer4 = Layer( label: "Layer04", prev: pLayer3 );
        NN.layers.append( pLayer4 )
        
        for (var ii=0; ii<lfNeuronCount; ++ii )
        {
            pLayer4.neurons.append(Neuron( label: String(ii) ))
        }
        
        for (var ii=0; ii<lfWeightCount; ++ii )
        {
            let initWeight = 0.05 * UNIFORM_PLUS_MINUS_ONE();
            pLayer4.weights.append(  Weight( value: initWeight ) );
        }
        
        // Interconnections with previous layer: fully-connected
        
        iNumWeight = 0;  // weights are not shared in this layer
        
        for (var fm=0; fm<lfNeuronCount; ++fm )
        {
            let n:Neuron = pLayer4.neurons[ fm ]
            n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ );  // bias weight

            for (var ii=0; ii<l3NeuronCount; ++ii )
            {
                n.AddConnection( ii, weightIndex: iNumWeight++ );
            }
        }
    }
    
    func UNIFORM_PLUS_MINUS_ONE() -> Double
    {
        // random value range: -1.0 ~ 1.0
        return (2.0 * Double(arc4random()) / Double(UINT32_MAX)) - 1.0
    }
}