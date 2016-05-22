//
//  Cnn.swift
//  vql
//
//  Created by len on 2015/6/14.
//  Copyright (c) 2015 len. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON

let dSigmoidFactor = 0.66666667 / 1.7159

func sigmoid(f: Double) -> Double
{
    return 1.7159 * tanh(0.66666667 * f)
}
func dSigmoid(f: Double) -> Double
{
    return dSigmoidFactor * (1.7159 + f ) * (1.7159 - f)
}

// Neural Network class

class NeuralNetwork : Mappable
{
    var layers = [Layer]()
    let iArchive = "Cache/neuralNetworkArchive"

    init()
    {
        
    }
    
    required init?(_ map: Map){
        
    }
    
    // Mappable
    func mapping(map: Map) {
        layers      <- map["layers"]
    }
    
    // Think with known weights
    final func forward(input:[Double]) -> [Double]
    {
        let firstLayer = layers.first!

        assert(firstLayer.neurons.count == input.count)
        // feed input to first layer
        for(var i = 0; i < input.count; ++i)
        {
            firstLayer.neurons[i].value = input[i]
        }
        firstLayer.debugPrint()
        
        // forward layer by layer
        for(var i = 1; i < layers.count; ++i)
        {
            layers[i].forward()
            layers[i].debugPrint()
        }

        let lastLayer = layers.last!
        // get outputs via last layer

        var output = [Double]()
        for(var i = 0; i < lastLayer.neurons.count; ++i)
        {
            output.append(lastLayer.neurons[i].value)
        }
        return output
    }
    
    // Training weights
    final func backPropagate(actualOutput:[Double], desiredOutput:[Double], eta:Double)
    {
        // Xnm1 means Xn-1
        
        // Backpropagates through the neural net
        // Proceed from the last layer to the first, iteratively
        // We calculate the last layer separately, and first,
        // since it provides the needed derviative
        // (i.e., dErr_wrt_dXnm1) for the previous layers
        
        // nomenclature:
        //
        // Err is output error of the entire neural net
        // Xn is the output vector on the n-th layer
        // Xnm1 is the output vector of the previous layer
        // Wn is the vector of weights of the n-th layer
        // Yn is the activation value of the n-th layer,
        // i.e., the weighted sum of inputs BEFORE
        //    the squashing function is applied
        // F is the squashing function: Xn = F(Yn)
        // F' is the derivative of the squashing function
        //   Conveniently, for F = tanh,
        //   then F'(Yn) = 1 - Xn^2, i.e., the derivative can be
        //   calculated from the output, without knowledge of the input



        var differentials = [[Double]]()
        for (var ii=0; ii<layers.count; ++ii )
        {
            differentials.append([Double](count: layers[ii].neurons.count, repeatedValue: 0.0))
        }


//        int iSize = m_Layers.size();

//        differentials.resize( iSize );

        
        // start the process by calculating dErr_wrt_dXn for the last layer.
        // for the standard MSE Err function
        // (i.e., 0.5*sumof( (actual-target)^2 ), this differential is simply
        // the difference between the target and the actual
        
        let lastLayer = layers.last!
        for (var ii=0; ii<lastLayer.neurons.count; ++ii )
        {
            differentials[differentials.count-1][ ii ] = actualOutput[ ii ] - desiredOutput[ ii ]
            //print(differentials[differentials.count-1][ ii ])
        }
        
        
        // store Xlast and reserve memory for
        // the remaining vectors stored in differentials
//        
//        differentials[ differentials.count-1 ] = dErr_wrt_dXlast  // last one

        
        // now iterate through all layers including
        // the last but excluding the first, and ask each of
        // them to backpropagate error and adjust
        // their weights, and to return the differential
        // dErr_wrt_dXnm1 for use as the input value
        // of dErr_wrt_dXn for the next iterated layer
        
//        let eta:Double = 0.0005;
        for (var bIt = differentials.count - 1; bIt > 0; --bIt) {
            layers[bIt].backPropagate(differentials[bIt], dErr_wrt_dXnm1: &differentials[bIt - 1], eta: eta)
        }

        var dSum:Double = 0
        for d in differentials[differentials.count - 1]
        {
            dSum += d
        }
    }
    
    func saveToFile()
    {
        print("func saveToFile()")

        let s = Mapper().toJSONString(self, prettyPrint: false)!
        // Takes long time to print out, write to file is faster
        
        let destinationPath = NSTemporaryDirectory() + "cnn.json"
        
        do {
            print("DestinationPath: \(destinationPath)")
            try s.writeToFile(destinationPath, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print(error)
        }
    }
    
    func loadFromFile() -> Bool
    {
        print("func loadFromFile()")

        let destinationPath = NSTemporaryDirectory() + "cnn.json"
        
        do {
            print("DestinationPath: \(destinationPath)")
            let s = try NSString(contentsOfFile: destinationPath, encoding: NSUTF8StringEncoding) as String
            if let nn:NeuralNetwork = Mapper<NeuralNetwork>().map(s)
            {
                print("Load \(nn.layers.count) layers from file")
                
                for (var i = 0; i < nn.layers.count; ++i)
                {
                  self.layers[i].weights = nn.layers[i].weights
                }
                
                for (var i = 0; i < nn.layers.count; ++i)
                {
                    for (var j = 0; j < nn.layers[i].neurons.count; ++j)
                    {
                        for (var k = 0; k < nn.layers[i].neurons[j].connections.count; ++k)
                        {
                            assert(self.layers[i].neurons[j].connections[k].weightIndex == nn.layers[i].neurons[j].connections[k].weightIndex)
                            assert(self.layers[i].neurons[j].connections[k].neuronIndex == nn.layers[i].neurons[j].connections[k].neuronIndex)

                            if (self.layers[i].neurons[j].connections[k].neuronIndex != nn.layers[i].neurons[j].connections[k].neuronIndex)
                            {
//                                print("\(self.layers[i].neurons[j].connections[k].neuronIndex) != \(nn.layers[i].neurons[j].connections[k].neuronIndex)")
//                                self.layers[i].neurons[j].connections[k].neuronIndex = nn.layers[i].neurons[j].connections[k].neuronIndex
                            }
                        }
                    }
                }

                print("Load layers done")
                return true
            }
        } catch let error as NSError {
            print(error)
        }
        return false
    }
    
    func loadFromTheano() -> Bool
    {

        print("func loadFromTheano()")
        
        let dir = NSTemporaryDirectory()
        
        // weight0.json ~ weight7.json
        var weightJsonStrings = [String]()
        let weightFileCount = 8
        for (var i = 0; i < weightFileCount; ++i)
        {
            let destinationPath = dir + "weight" + String(i) + ".json"
            do {
                print("DestinationPath: \(destinationPath)")
                let s = try NSString(contentsOfFile: destinationPath, encoding: NSUTF8StringEncoding) as String
                weightJsonStrings.append(s)
            } catch let error as NSError {
                print(error)
                return false
            }
        }
        
        // make sure we can read weights successfully from json strings
        for l in layers
        {
            for w in l.weights
            {
                w.value = 0
            }
        }

        
        // layer one:
        // This layer is a convolutional layer that
        // has 6 feature maps.  Each feature
        // map is 13x13, and each unit in the
        // feature maps is a 5x5 convolutional kernel
        // of the input layer.
        // So, there are 13x13x6 = 1014 neurons, (5x5+1)x6 = 156 weights
        
        // Note: updated 6 to 20
        
        let featMapCount = 20
        let kernelSize = 5
        let kernelArea = kernelSize * kernelSize
        let kernelWeightCount = 1 + kernelArea

        let l1 = layers[1]
        
        // w7: 20 bias
        if let dataFromString = weightJsonStrings[7].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)
            
            var shift = 0
            for (_, subJson) in json {
                l1.weights[shift].value = subJson.doubleValue
                shift += kernelWeightCount
            }
            assert(shift == l1.weights.count)
        }
        
        // w6: 20 x 1 (one image as input) x ( 1 + 5 x 5)
        if let dataFromString = weightJsonStrings[6].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)

            // 1 ~ 20
            var shift = 0
            for (_, sj) in json {
                ++shift // skip bias
                for (_, sj2) in sj[0] {
                    for (_, sj3) in sj2 {
                        l1.weights[shift].value = sj3.doubleValue
                        ++shift
                    }
                }
            }
            assert(shift == l1.weights.count)
        }
        
        // layer two:
        // This layer is a convolutional layer
        // that has 50 feature maps.  Each feature
        // map is 5x5, and each unit in the feature
        // maps is a 5x5 convolutional kernel
        // of corresponding areas of all 6 of the
        // previous layers, each of which is a 13x13 feature map
        // So, there are 5x5x50 = 1250 neurons, (5x5+1)x6x50 = 7800 weights
        
        // Note: updated 6 to 20
        
        let l2 = layers[2]
        
        // w5: 50
        if let dataFromString = weightJsonStrings[5].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)
            
            var shift = 0
            for (_, subJson) in json {
                for (var i = 0; i < featMapCount; ++i)
                {
                    l2.weights[shift].value = subJson.doubleValue
                    shift += kernelWeightCount
                }
            }
            assert(shift == l2.weights.count)
        }
        
        // w4: 50 x 20 x ( 1 + 5 x 5) = 26000
        if let dataFromString = weightJsonStrings[4].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)
            
            // 1 ~ 20
            var shift = 0
            for (_, sj) in json {
                for (_, sj2) in sj {
                    ++shift // skip bias
                    for (_, sj3) in sj2 {
                        for (_, sj4) in sj3 {
                            l2.weights[shift].value = sj4.doubleValue
                            ++shift
                        }
                    }
                }
            }
            assert(shift == l2.weights.count)
        }
    
//        # the HiddenLayer being fully-connected, it operates on 2D matrices of
//        # shape (batch_size, num_pixels) (i.e matrix of rasterized images).
//        # This will generate a matrix of shape (batch_size, nkerns[1] * 4 * 4),
//        # or (500, 50 * 4 * 4) = (500, 800) with the default values.
//        layer2_input = layer1.output.flatten(2)
        
        let l3 = layers[3]
        // weights = 400500 = 500 x (1 + 800)
        
        let l2NeuronCount = 50 * 4 * 4
        // 625500 = 500 x (1250 + 1)
        // w3: 500
        
        let l2NcPlus1 = (1 + l2NeuronCount)
        // 500 is middle layer of fully-connetced NN
        let l3WeightCount = 500 * l2NcPlus1
        
        if let dataFromString = weightJsonStrings[3].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)
            
            var shift = 0
            for (_, subJson) in json {
                l3.weights[shift].value = subJson.doubleValue
                shift += l2NcPlus1
            }
            assert(shift == l3.weights.count)
        }
        
        // w2: 800 x 500
        // !!!!!!!!!!!!!!!!!!!
        // 
        // Why order different
        //
        // !!!!!!!!!!!!!!!!!!!
        if let dataFromString = weightJsonStrings[2].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)
            
            var ary = [[Double]](count:500, repeatedValue: [Double](count:800, repeatedValue: 0.0))
            var i800 = 0, i500 = 0
            for (_, sj) in json {
                i500 = 0
                for (_, sj2) in sj {
                    ary[i500++][i800] = sj2.doubleValue
                }
                i800++
            }
            
            assert(i500 == 500)
            assert(i800 == 800)
            
            var shift = 0
            for (row) in ary {
                ++shift // skip bias
                for (value) in row {
                    l3.weights[shift].value = value
                    ++shift
                }
            }
            
            assert(shift == l3.weights.count)
        }
        
        // Finally, mapping to digits 0 ~ 9
        
        let l4 = layers[4]
        // weights = 5010 = 10 x (1 + 500)
        let l3NeuronCount = 500
        let l3NcPlus1 = (1 + l3NeuronCount)
        let l4WeightCount = 10 * l3NcPlus1
        
        // w1: 10
        if let dataFromString = weightJsonStrings[1].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)
            
            var shift = 0
            for (_, subJson) in json {
                l4.weights[shift].value = subJson.doubleValue
                shift += l3NcPlus1
            }
            assert(shift == l4WeightCount)
        }
        
        // w0: 500 x 10
        // !!!!!!!!!!!!!!!!!!!
        //
        // Why order different
        //
        // !!!!!!!!!!!!!!!!!!!
        if let dataFromString = weightJsonStrings[0].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        {
            let json = JSON(data: dataFromString)
            
            var ary = [[Double]](count:10, repeatedValue: [Double](count:500, repeatedValue: 0.0))
            var i500 = 0, i10 = 0
            for (_, sj) in json {
                i10 = 0
                for (_, sj2) in sj {
                    ary[i10++][i500] = sj2.doubleValue
                }
                i500++
            }
            
            assert(i10 == 10)
            assert(i500 == 500)
            
            var shift = 0
            for (row) in ary {
                ++shift // skip bias
                for (value) in row {
                    l4.weights[shift].value = value
                    ++shift
                }
            }
            
            assert(shift == l4WeightCount)
        }
        
        return true
        
    }
}


// Layer class
class Layer : Mappable
{
    var prev:Layer!
    var neurons = [Neuron]()
    var weights = [Weight]()
    let ULONG_MAX:Int = 65535
    var label:String = ""

    init(label:String)
    {
        self.label = label
    }
    
    init(label:String, prev:Layer)
    {
        self.label = label
        self.prev = prev
    }
    
    required init?(_ map: Map){
        
    }
    
    // Mappable
    func mapping(map: Map) {
        label      <- map["label"]
        neurons    <- map["n"]
        weights    <- map["w"]
    }
    
    final func forward() {
        assert(prev.neurons.count > 0, "Previous layer must has neurons !")
        assert(prev.label != label)

        for n in neurons {
            let firstConn = n.connections.first!
            assert(firstConn.weightIndex < weights.count)

            // weight of the first connection is the bias;
            // its neuron-index is ignored

            let bias:Double = weights[firstConn.weightIndex].value

            var sum:Double = 0

            for (var i = 1; i < n.connections.count; ++i) {
                let conn = n.connections[i]
                assert(conn.weightIndex < weights.count)
                assert(conn.neuronIndex < prev.neurons.count)

                let w = weights[conn.weightIndex].value

                if (w != 0) {
                    var nv = prev.neurons[conn.neuronIndex].value
                    let v = w * nv
                    if (v != 0) {
                        sum += v
                    }
                }
            }

            // activation function
            let s = sigmoid(sum + bias)
            n.value = s
        }
    }
    
    final func backPropagate(dErr_wrt_dXn:[Double], inout dErr_wrt_dXnm1:[Double], eta:Double)
    {
        var dErr_wrt_dYn = [Double]()
        // calculate equation (3): dErr_wrt_dYn = F'(Yn) * dErr_wrt_Xn

        for (var ii = 0; ii < neurons.count; ++ii)
        {
            let output = neurons[ ii ].value
            dErr_wrt_dYn.append(dSigmoid( output ) * dErr_wrt_dXn[ ii ])
        }
        
        // calculate equation (4): dErr_wrt_Wn = Xnm1 * dErr_wrt_Yn
        // For each neuron in this layer, go through
        // the list of connections from the prior layer, and
        // update the differential for the corresponding weight
        
        var dErr_wrt_dWn = [Double](count: weights.count, repeatedValue: 0.0)
        
        var ii = 0
        for n in neurons
        {
            // for simplifying the terminology

            for c in n.connections
            {
                var x:Double
                let nIdx = c.neuronIndex
                if ( nIdx == ULONG_MAX )
                {
                    x = 1.0  // this is the bias weight
                }
                else
                {
                    x = prev.neurons[nIdx].value
                }
                
                dErr_wrt_dWn[ c.weightIndex ] += dErr_wrt_dYn[ ii ] * x
            }
            
            ++ii
        }
        
        // calculate equation (5): dErr_wrt_Xnm1 = Wn * dErr_wrt_dYn,
        // which is needed as the input value of
        // dErr_wrt_Xn for backpropagation of the next (i.e., previous) layer
        // For each neuron in this layer
        
        ii = 0
        for n in neurons
        {
            // for simplifying the terminology
            
            for c in n.connections
            {
                let nIdx = c.neuronIndex
                if ( nIdx != ULONG_MAX )
                {
                    // we exclude ULONG_MAX, which signifies
                    // the phantom bias neuron with
                    // constant output of "1",
                    // since we cannot train the bias neuron
                    
                    // nIndex = kk
                    
                    dErr_wrt_dXnm1[ nIdx ] += dErr_wrt_dYn[ ii ] * weights[ c.weightIndex ].value
                }
            }
            
            ii++  // ii tracks the neuron iterator
        }
        
        // calculate equation (6): update the weights
        // in this layer using dErr_wrt_dW (from
        // equation (4)    and the learning rate eta
        
        // turing bias too here
        for (var jj = 0; jj < weights.count; ++jj)
        {
            let oldValue = weights[ jj ].value
            let d = dErr_wrt_dWn[ jj ]
            let diff = eta * d

            let newValue = oldValue/*.dd*/ - diff
            
            weights[jj].value = newValue
        }
    }
    
    final func debugPrint()
    {
//        printNeurons()
//        printWeights()
    }
    
    final func printNeurons() {
        print("func printNeurons()")
        
        var s:String = ""
        for n in neurons
        {
            s += " \(n.value)"
        }
        // Takes long time to print out, write to file is faster
        
        let destinationPath = NSTemporaryDirectory() + label + "_neurons.json"
        
        do {
            print("DestinationPath: \(destinationPath)")
            try s.writeToFile(destinationPath, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print(error)
        }
    }
    
    final func printWeights() {
        print("func printWeights()")
        
        var s:String = ""
        for n in weights
        {
            s += " \(n.value)"
        }
        // Takes long time to print out, write to file is faster
        
        let destinationPath = NSTemporaryDirectory() + label + "_weights.json"
        
        do {
            print("DestinationPath: \(destinationPath)")
            try s.writeToFile(destinationPath, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError {
            print(error)
        }
    }
}


// Neuron class

class Neuron: Mappable
{
    var label:String = ""
    var value:Double = 0.0
    var connections = [Connection]()
    
    init()
    {
    }
    init(value:Double)
    {
        self.value = value
    }
    init(label:String)
    {
        self.label = label
    }
    
    func AddConnection(neuronIndex:Int, weightIndex:Int)
    {
        connections.append(Connection(neuronIndex: neuronIndex, weightIndex: weightIndex))
    }
    
    required init?(_ map: Map){
        
    }
    
    // Mappable
    func mapping(map: Map) {
        label    <- map["label"]
        value    <- map["v"]
        connections    <- map["connections"]
    }
}


// Connection class

class Connection: Mappable
{
    var neuronIndex:Int = 0
    var weightIndex:Int = 0
    init(neuronIndex:Int, weightIndex:Int)
    {
        self.neuronIndex = neuronIndex
        self.weightIndex = weightIndex
    }
    
    required init?(_ map: Map){
        
    }
    
    // Mappable
    func mapping(map: Map) {
        neuronIndex    <- map["n"]
        weightIndex    <- map["w"]
    }
}


// Weight class

class Weight: Mappable
{
    var value:Double  = 0.0

    init(value:Double)
    {
        self.value = value
    }
    
    required init?(_ map: Map){
        
    }
    
    // Mappable
    func mapping(map: Map) {
        value    <- map["v"]
    }
}