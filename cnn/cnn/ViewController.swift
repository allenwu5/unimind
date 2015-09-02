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
        
        let mnist = Mnist()
        mnist.read()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

