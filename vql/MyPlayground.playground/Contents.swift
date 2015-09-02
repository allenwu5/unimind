//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
class Layer{
    var ary:[[Double]]
    
    init() {
        ary = [[Double]](count: 10, repeatedValue:[Double](count: 10, repeatedValue:1))
        for var i = 0; i < ary.count; i++ {
            for var j = 0; j < ary[i].count; j++ {
                ary[i][j] = sigmod(ary[i][j])
            }
        }
    }
    
    func dump() {
        for var i = 0; i < ary.count; i++ {
            for var j = 0; j < ary[i].count; j++ {
                println("m[\(i),\(j)] = \(ary[i][j])")
            }
        }
    }
    
    func sigmod(d: Double)->Double{
            return 1.0 / (1.0 + exp(-d))
        }
}

let l = Layer()
l.dump()

