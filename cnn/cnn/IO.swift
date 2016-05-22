//
//  IO.swift
//  cnn
//
//  Created by len on 2015/12/1.
//  Copyright © 2015年 len. All rights reserved.
//

import Foundation

class IO
{
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
