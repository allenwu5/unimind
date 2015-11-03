//
//  Cnn.swift
//  vql
//
//  Created by len on 2015/6/14.
//  Copyright (c) 2015 len. All rights reserved.
//

import Foundation
import ObjectMapper

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
        
        // forward layer by layer
        for(var i = 1; i < layers.count; ++i)
        {
            layers[i].forward()
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
    
    func loadFromFile()
    {
        print("func loadFromFile()")

        let destinationPath = NSTemporaryDirectory() + "cnn.json"
        
        do {
            print("DestinationPath: \(destinationPath)")
            let s = try NSString(contentsOfFile: destinationPath, encoding: NSUTF8StringEncoding) as String
            if let nn:NeuralNetwork = Mapper<NeuralNetwork>().map(s)
            {
                print("Load \(nn.layers.count) layers from file")
                print("Connect layers")
                for (var i = 0; i < nn.layers.count - 1; ++i)
                {
                    nn.layers[i + 1].prev = nn.layers[i]
                }
                
                self.layers = nn.layers
                print("Load layers done")
            }
            else
            {
                print("nn is null")
            }
            
        } catch let error as NSError {
            print(error)
        }
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
        //print(label)
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
                    let v = w * prev.neurons[conn.neuronIndex].value
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
            
            weights[ jj ].value = newValue
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