//
//  InstructionsViewController.swift
//  urban explorAR
//
//  Created by Christopher Wainwright on 19/03/2019.
//  Copyright © 2019 Christopher Wainwright. All rights reserved.
//

import UIKit

class InstructionsViewController: UIViewController {
    
    // outlet for text view
    @IBOutlet weak var textView: UITextView!
    
    // return to home when back clicked
    @IBAction func backBtnClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make text view corners rounded
        textView.layer.cornerRadius = 10

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
