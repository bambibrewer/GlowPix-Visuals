//
//  KeyPadViewController.swift
//  FinchApp
//
//  Created by Bambi Brewer on 11/12/20.
//  Copyright © 2020 none. All rights reserved.
//

import UIKit

protocol KeyPadPopupDelegate {
   func numberChanged(number: Int?)
}

class KeyPadViewController: UIViewController, OwletKeypadDelegate {
   
   @IBOutlet var keyPadView: OwletKeypadView!
   
   var keyPadDelegate: KeyPadPopupDelegate?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      keyPadView.delegate = self
   }
   
   func numberChanged(number: Int?) {
      keyPadDelegate?.numberChanged(number: number)
   }
   
}
