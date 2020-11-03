//
//  TopMenuViewController.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol TopMenuViewControllerDelegate {
    func didPressNewProgramButton()
    func didChangeLevel(to newLevel: Int)
}

class TopMenuViewController: UIViewController, UIPopoverPresentationControllerDelegate, LevelTableViewControllerDelegate {
    
    @IBOutlet weak var levelButton: UIButton!
    
    var delegate: TopMenuViewControllerDelegate?
    
    var currentLevel: Int = 1
      
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let backgroundImage = UIImage(named: "Blue Background") {
            view.backgroundColor = UIColor(patternImage: backgroundImage)
        }

        levelButton.setTitle("Level \(currentLevel)", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view will appear")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBActions
    
   
    @IBAction func newProgram(_ sender: Any) {
        delegate?.didPressNewProgramButton()
    }
    
    @IBAction func changeLevel(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let levelListVC = storyboard.instantiateViewController(withIdentifier: "levelList") as? LevelTableViewController {
            
            levelListVC.modalPresentationStyle = .popover
            levelListVC.popoverPresentationController?.permittedArrowDirections = .any
            levelListVC.popoverPresentationController?.delegate = self
            levelListVC.popoverPresentationController?.sourceView = sender
            levelListVC.popoverPresentationController?.sourceRect = sender.bounds
            
            levelListVC.levelSelected = currentLevel
            levelListVC.delegate = self
            
            self.present(levelListVC, animated: true)
        }
    }
    
    
    // MARK: UIPopoverPresentationControllerDelegate methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none  //I don't think this method is being used anymore.
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
    
    
    //MARK: LevelTableViewControllerDelegate methods
    func selectLevel(_ level: Int) {
        currentLevel = level
        levelButton.setTitle("Level \(level)", for: .normal) 
        delegate?.didChangeLevel(to: level)
    }
    
    
    

    //MARK: Other
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 200, y: 200, width: 400, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    

}
