//
//  Cnn.swift
//  vql
//
//  Created by len on 2015/7/25.
//  Copyright (c) 2015年 len. All rights reserved.
//

import Foundation


class RecognizeHandWrittenDigits
{
    let ULONG_MAX:Int = 65535
    let NN = NeuralNetwork()  // for easier nomenclature
    
    func initNN()
    {
        // initialize and build the neural net
        
        
        // NN.initialize()
        
        // layer zero, the input layer.
        // Create neurons: exactly the same number of neurons as the input
        // vector of 29x29=841 pixels, and no weights/connections
        
        let inputSize = 29
        let inputArea = inputSize * inputSize
        
        
        var pLayer = Layer(label:"Layer00")
        NN.layers.append(pLayer)
        
        for (var ii=0; ii<inputArea; ++ii )
        {
            pLayer.neurons.append(Neuron())
        }
        
        // layer one:
        // This layer is a convolutional layer that
        // has 6 feature maps.  Each feature
        // map is 13x13, and each unit in the
        // feature maps is a 5x5 convolutional kernel
        // of the input layer.
        // So, there are 13x13x6 = 1014 neurons, (5x5+1)x6 = 156 weights
        let featMapCount = 6
        let featMapSize = 13
        let featMapArea = featMapSize * featMapSize
        let kernelSize = 5
        let kernelArea = kernelSize * kernelSize
        let kernelWeightCount = 1 + kernelArea
        
        let neuronCount = featMapCount * featMapArea // feat count times feat map area
        let weightCount = featMapCount * kernelWeightCount // feat count times kernel weight
        

        pLayer = Layer(label:"Layer01",prev: pLayer)

        NN.layers.append( pLayer );
        
        for (var ii=0; ii<neuronCount; ++ii )
        {
            pLayer.neurons.append(Neuron())
        }
        
        for (var ii=0; ii<weightCount; ++ii )
        {
            // uniform random distribution
            pLayer.weights.append( Weight(value: 0.05 * UNIFORM_PLUS_MINUS_ONE()) )
        }
        
        // interconnections with previous layer: this is difficult
        // The previous layer is a top-down bitmap
        // image that has been padded to size 29x29
        // Each neuron in this layer is connected
        // to a 5x5 kernel in its feature map, which
        // is also a top-down bitmap of size 13x13.
        // We move the kernel by TWO pixels, i.e., we
        // skip every other pixel in the input image
        
        let kernelTemplate:[Int] = [
            0,  1,  2,  3,  4,
            29, 30, 31, 32, 33,
            58, 59, 60, 61, 62,
            87, 88, 89, 90, 91,
            116,117,118,119,120 ];
        

        
//        int fm;  // "fm" stands for "feature map"
        
        for (var fm=0; fm<featMapCount; ++fm)
        {
            for (var ii=0; ii<featMapSize; ++ii )
            {
                for (var jj=0; jj<featMapSize; ++jj )
                {
                    // 26 is the number of weights per feature map
                    var iNumWeight:Int = fm * kernelWeightCount;
                    let n = pLayer.neurons[ jj + ii*featMapSize + fm*featMapArea ]
                    
                    n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ )  // bias weight
                    
                    for (var kk=0; kk<kernelArea; ++kk )
                    {
                        // note: max val of index == 840,
                        // corresponding to 841 neurons in prev layer
                        n.AddConnection( 2 * (jj + inputSize * ii) + kernelTemplate[kk], weightIndex: iNumWeight++ );
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
        let l2NeuronCount = l2FeatMapCount * kernelArea
        let l2WeightCount = kernelWeightCount * featMapCount * l2FeatMapCount
        
        
        
        pLayer = Layer(label: "Layer02", prev: pLayer );
        NN.layers.append( pLayer );
        
        for (var ii=0; ii<l2NeuronCount; ++ii )
        {
            pLayer.neurons.append(Neuron(label: String(ii)) );
        }
        
        for (var ii=0; ii<l2WeightCount; ++ii )
        {
            pLayer.weights.append( Weight( value: 0.05 * UNIFORM_PLUS_MINUS_ONE() ) )
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
        
        let kernelTemplate2:[Int] = [
            0,  1,  2,  3,  4,
            13, 14, 15, 16, 17,
            26, 27, 28, 29, 30,
            39, 40, 41, 42, 43,
            52, 53, 54, 55, 56   ]
        
        
        for (var fm=0; fm<l2FeatMapCount; ++fm)
        {
            for (var ii=0; ii<kernelSize; ++ii )
            {
                for (var jj=0; jj<kernelSize; ++jj )
                {
                    // 26 is the number of weights per feature map
                    var iNumWeight = fm * kernelWeightCount;
                    var n:Neuron = pLayer.neurons[ jj + ii*kernelSize + fm*kernelArea ]
                    
                    n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ )  // bias weight
                    
                    for (var kk=0; kk<kernelArea; ++kk )
                    {
                        // note: max val of index == 1013,
                        // corresponding to 1014 neurons in prev layer
                        n.AddConnection(       2*jj + 26*ii +
                            kernelTemplate2[kk], weightIndex: iNumWeight++ );
                        n.AddConnection( 169 + 2*jj + 26*ii +
                            kernelTemplate2[kk], weightIndex: iNumWeight++ );
                        n.AddConnection( 338 + 2*jj + 26*ii +
                            kernelTemplate2[kk], weightIndex: iNumWeight++ );
                        n.AddConnection( 507 + 2*jj + 26*ii +
                            kernelTemplate2[kk], weightIndex: iNumWeight++ );
                        n.AddConnection( 676 + 2*jj + 26*ii +
                            kernelTemplate2[kk], weightIndex: iNumWeight++ );
                        n.AddConnection( 845 + 2*jj + 26*ii + 
                            kernelTemplate2[kk], weightIndex: iNumWeight++ );
                    }
                }
            }
        }
        
        // layer three:
        // This layer is a fully-connected layer
        // with 100 units.  Since it is fully-connected,
        // each of the 100 neurons in the
        // layer is connected to all 1250 neurons in
        // the previous layer.
        // So, there are 100 neurons and 100*(1250+1)=125100 weights
        
        let l3NeuronCount = 100
        let l3WeightCount = l3NeuronCount * (1 + l2NeuronCount)
        
        pLayer = Layer(label: "Layer03", prev: pLayer )
        NN.layers.append( pLayer )
        
        for (var ii=0; ii<l3NeuronCount; ++ii )
        {
            pLayer.neurons.append(Neuron( label: String(ii) ))
        }
        
        for (var ii=0; ii<l3WeightCount; ++ii )
        {
            var initWeight = 0.05 * UNIFORM_PLUS_MINUS_ONE();
            pLayer.weights.append(  Weight( value: initWeight ) );
        }
        
        // Interconnections with previous layer: fully-connected
        
        var iNumWeight = 0;  // weights are not shared in this layer
        
        for (var fm=0; fm<l3NeuronCount; ++fm )
        {
            var n:Neuron = pLayer.neurons[ fm ]
            n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ );  // bias weight
            
            for (var ii=0; ii<l2NeuronCount; ++ii )
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
        let lfWeightCount = lfNeuronCount * (1 + l3NeuronCount)
        
        pLayer = Layer( label: "Layer04", prev: pLayer );
        NN.layers.append( pLayer )
        
        for (var ii=0; ii<lfNeuronCount; ++ii )
        {
            pLayer.neurons.append(Neuron( label: String(ii) ))
        }
        
        for (var ii=0; ii<lfWeightCount; ++ii )
        {
            var initWeight = 0.05 * UNIFORM_PLUS_MINUS_ONE();
            pLayer.weights.append(  Weight( value: initWeight ) );
        }
        
        // Interconnections with previous layer: fully-connected
        
        iNumWeight = 0;  // weights are not shared in this layer
        
        for (var fm=0; fm<lfNeuronCount; ++fm )
        {
//            NNNeuron& n = *( pLayer->m_Neurons[ fm ] );
            var n:Neuron = pLayer.neurons[ fm ]
//            n.AddConnection( ULONG_MAX, iNumWeight++ );  // bias weight
            n.AddConnection( ULONG_MAX, weightIndex: iNumWeight++ );  // bias weight

            for (var ii=0; ii<l3NeuronCount; ++ii )
            {
//                n.AddConnection( ii, iNumWeight++ );
                n.AddConnection( ii, weightIndex: iNumWeight++ );

            }
        }
        
        
//        SetModifiedFlag( TRUE );SetModifiedFlag
    }
    
    func UNIFORM_PLUS_MINUS_ONE() -> Float
    {
        // random value range: -1.0 ~ 1.0
        return (2.0 * Float(arc4random()) / Float(UINT32_MAX)) - 1.0
    }
}