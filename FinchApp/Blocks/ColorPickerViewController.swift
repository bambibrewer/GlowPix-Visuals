//
//  ColorPickerViewController.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 4/11/18.
//  Copyright © 2018 none. All rights reserved.
//

import UIKit

protocol ColorPickerViewControllerDelegate {
    func didPickColor(_ color: UIColor)
}

class ColorPickerViewController: UIViewController, HSBColorPickerDelegate {

    @IBOutlet weak var colorPicker: HSBColorPicker!
    
    var delegate: ColorPickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        colorPicker.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        delegate?.didPickColor(color)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    

}
