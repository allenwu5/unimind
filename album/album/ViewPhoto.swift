//
//  ViewPhoto.swift
//  album
//
//  Created by len on 2016/12/15.
//  Copyright © 2016年 unimind. All rights reserved.
//

import UIKit

class ViewPhoto: UIViewController {
    @IBOutlet weak var imgView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func btnCancel(_ sender: Any) {
        print("cancel clicked")
        
//        When you call popToRootViewController, the currently visible viewController disappears (after calling viewWillDisappear) and the first controller on the stack is shown.
//        All viewControllers in between are deallocated (after calling dealloc) without being shown. And if they are not shown, they can't disappear.
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func btnExport(_ sender: Any) {
        print("export clicked")
    }
    
    @IBAction func btnTrash(_ sender: Any) {
        print("trash clicked")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
