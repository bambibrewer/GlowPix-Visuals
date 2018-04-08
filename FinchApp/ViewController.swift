//
//  ViewController.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, TopMenuViewControllerDelegate {
    
    @IBOutlet weak var canvas: UIView!


    @IBOutlet weak var motionTabButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var soundTabButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var colorTabButtonHeight: NSLayoutConstraint!
    

    @IBOutlet weak var tabsView: UIView!
    @IBOutlet weak var motionTabView: UIView!
    @IBOutlet weak var soundTabView: UIView!
    @IBOutlet weak var colorTabView: UIView!
    
    @IBOutlet weak var trashImage: UIImageView!
    
    //Motion Menu
    @IBOutlet weak var moveForwardStatic: UIImageView!
    @IBOutlet weak var moveBackwardStatic: UIImageView!
    @IBOutlet weak var turnLeftStatic: UIImageView!
    @IBOutlet weak var turnRightStatic: UIImageView!
    
    //Sound Menu
    @IBOutlet weak var soundStatic: UIImageView!
    
    //Color Menu
    @IBOutlet weak var colorRedStatic: UIImageView!
    @IBOutlet weak var colorGreenStatic: UIImageView!
    @IBOutlet weak var colorBlueStatic: UIImageView!
    @IBOutlet weak var colorOffStatic: UIImageView!
    

    var tempImageViews: [Int: UIImageView] = [:]
    
    let topMenuViewController = TopMenuViewController()
    var blocks:[UIImageView:Block] = [:]
    var startBlock: Block?
    var level: Int = 1
    
    //Sound Effects
    var blockDropSoundPlayer: AVAudioPlayer?
    var selectSoundPlayer: AVAudioPlayer?
    var trashSoundPlayer: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add the top menu
        topMenuViewController.delegate = self
        self.addChildViewController(topMenuViewController)
        self.view.addSubview(topMenuViewController.view)
        topMenuViewController.didMove(toParentViewController: self)
        topMenuViewController.view.frame = CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY, width: self.view.bounds.width, height: 80.0)
        
        //Load sound effects
        if let blockDrop = NSDataAsset(name: "block-drop") {
            do {
                try blockDropSoundPlayer = AVAudioPlayer(data: blockDrop.data)
            } catch {
                print ("Could not load block drop sound")
            }
        }
        if let select = NSDataAsset(name: "block-select and button-click") {
            do {
                try selectSoundPlayer = AVAudioPlayer(data: select.data)
            } catch {
                print ("Could not load select sound")
            }
        }
        if let trash = NSDataAsset(name: "trash-sound") {
            do {
                try trashSoundPlayer = AVAudioPlayer(data: trash.data)
            } catch {
                print ("Could not load trash sound")
            }
        }
        
        //Make the canvas moveable
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        canvas.addGestureRecognizer(panGestureRecognizer)
        
        //Put the trash can out of sight for now
        self.view.sendSubview(toBack: trashImage)
        
        //Setup motion menu blocks
        moveForwardStatic.isUserInteractionEnabled = true
        let moveForwardGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        moveForwardStatic.addGestureRecognizer(moveForwardGestureRecognizer)
        
        moveBackwardStatic.isUserInteractionEnabled = true
        let moveBackwardGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        moveBackwardStatic.addGestureRecognizer(moveBackwardGestureRecognizer)
        
        turnLeftStatic.isUserInteractionEnabled = true
        let turnLeftGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        turnLeftStatic.addGestureRecognizer(turnLeftGestureRecognizer)
        
        turnRightStatic.isUserInteractionEnabled = true
        let turnRightGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        turnRightStatic.addGestureRecognizer(turnRightGestureRecognizer)
        
        //Setup sound menu blocks
        soundStatic.isUserInteractionEnabled = true
        let soundGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        soundStatic.addGestureRecognizer(soundGestureRecognizer)
        
        //Setup color menu blocks
        colorRedStatic.isUserInteractionEnabled = true
        let colorRedGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        colorRedStatic.addGestureRecognizer(colorRedGestureRecognizer)
        
        colorGreenStatic.isUserInteractionEnabled = true
        let colorGreenGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        colorGreenStatic.addGestureRecognizer(colorGreenGestureRecognizer)
        
        colorBlueStatic.isUserInteractionEnabled = true
        let colorBlueGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        colorBlueStatic.addGestureRecognizer(colorBlueGestureRecognizer)
        
        colorOffStatic.isUserInteractionEnabled = true
        let colorOffGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        colorOffStatic.addGestureRecognizer(colorOffGestureRecognizer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func newBlock(typeString: String, view: UIImageView) {
        if blocks[view] != nil{
            print("why does this view already have a block??")
        }
        
        view.isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleBlockPanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        canvas.addSubview(view) //TODO: Make sure it actually is on the canvas
        blocks[view] = Block(withTypeFromString: typeString, withView: view, forLevel: level)
    }

    //MARK: Button Actions
    
    @IBAction func showMotionTab(_ sender: Any) {
        motionTabButtonHeight.constant = 50
        soundTabButtonHeight.constant = 30
        colorTabButtonHeight.constant = 30
        
        tabsView.bringSubview(toFront: motionTabView)
    }
    @IBAction func showSoundTab(_ sender: Any) {
        motionTabButtonHeight.constant = 30
        soundTabButtonHeight.constant = 50
        colorTabButtonHeight.constant = 30
        
        tabsView.bringSubview(toFront: soundTabView)
    }
    @IBAction func showColorTab(_ sender: Any) {
        motionTabButtonHeight.constant = 30
        soundTabButtonHeight.constant = 30
        colorTabButtonHeight.constant = 50
        
        tabsView.bringSubview(toFront: colorTabView)
    }

    //MARK: Top Menu Delegate methods
    
    func didPressNewProgramButton() {
        print("pressed new program")
        for (imageView, _) in blocks {
            imageView.removeFromSuperview()
        }
        blocks = [:]
        
        let startView = UIImageView(image: UIImage(named: "control-start"))
        startView.frame = CGRect(x: self.view.bounds.midX/2.0, y: self.view.bounds.midY-25.0, width: 80.0, height: 60.0)
        
        newBlock(typeString: "control-start", view: startView)
        if let tmp = blocks[startView] {
            startBlock = tmp
        } else {
            print("There should be a block in the array for the start block now!")
        }
    }
    
    func didPressRunProgramButton() {
        print("pressed run program")
        //TODO: some sort of message if there is no start block? or no blocks connected?
        guard let startBlock = startBlock else {
            print ("Cannot run when no start block is shown.")
            return
        }
        
        guard let finchID = topMenuViewController.finchID else {
            print("No robot selected, nothing to run on.")
            return
        }
        
        if topMenuViewController.isConnected {
            guard let finch = BLECentralManager.shared.robotForID(finchID) as? FinchPeripheral else {
                print("Could not find finch for id given. Can not run program.")
                return
            }
            startBlock.execute(on: finch)
        } else {
            print ("Cannot run if robot is not connected.")
        }
    }
    
    //MARK: Gesture Recognizer Functions
    
    @objc func handlePanGesture (_ gesture: UIPanGestureRecognizer) {
        if (gesture.state == UIGestureRecognizerState.changed) {
            //find translation to offset by
            let translation = gesture.translation(in: gesture.view)
            if let view = gesture.view {
                view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            }
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
        }
    }
    
    @objc func handleBlockPanGesture (_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            if let view = gesture.view as? UIImageView, let block = blocks[view] {
                //if there is a block ahead of us on the chain, moving this block will change that
                block.detachPreviousBlock()
            }
            self.view.bringSubview(toFront: trashImage)
        case .changed:
            //find translation to offset by
            let translation = gesture.translation(in: gesture.view)
            if let view = gesture.view as? UIImageView {
                //view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
                if let headBlock = blocks[view] {
                    var b : Block? = headBlock
                    while let block = b {
                        block.imageView.center = CGPoint(x: block.imageView.center.x + translation.x, y: block.imageView.center.y + translation.y)
                        b = b?.nextBlock
                    }
                } else {
                    fatalError("No block for panning view!")
                }
                
                var foundNeighbor = false
                for (bView,block) in blocks {
                    if block.nextBlock == nil {
                        let bx = bView.center.x
                        let by = bView.center.y
                        if view.center.x > bx + 50 && view.center.x < bx + 100 && view.center.y > by - 60 && view.center.y < by + 60{
                            if tempImageViews[gesture.hash] == nil { //TODO: What if you are near 2 blocks?
                                let tmp = UIImageView(image: view.image)
                                tmp.alpha = 0.5
                                tmp.frame = view.frame
                                tmp.center = CGPoint(x: bx + block.offset, y: by)
                                canvas.addSubview(tmp)
                                tempImageViews[gesture.hash] = tmp
                            }
                            foundNeighbor = true
                        }
                    }
                }
                if !foundNeighbor {
                    if let tmpImageView = tempImageViews[gesture.hash] {
                        tmpImageView.removeFromSuperview()
                        tempImageViews[gesture.hash] = nil
                    }
                }
            }
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
        case .ended:
            self.view.sendSubview(toBack: trashImage)
            if let tmpView = tempImageViews[gesture.hash] {
                tmpView.removeFromSuperview()
                tempImageViews[gesture.hash] = nil
            }
            if let view = gesture.view as? UIImageView {
                for (bView,block) in blocks {
                    if block.nextBlock == nil {
                        var bx = bView.center.x
                        var by = bView.center.y
                        if view.center.x > bx + 50 && view.center.x < bx + 100 && view.center.y > by - 60 && view.center.y < by + 60{
                            view.center = CGPoint(x: bx + 63, y: by)
                            if let b = blocks[view] {
                                block.attachBlock(b)
                                var tmp : Block? = b
                                while let nextBlock = tmp {
                                    guard let offset = nextBlock.previousBlock?.offset else {
                                        fatalError("There should be an offset to use here!")
                                    }
                                    nextBlock.imageView.center = CGPoint(x: bx + offset, y: by)
                                    bx = nextBlock.imageView.center.x
                                    by = nextBlock.imageView.center.y
                                    tmp = tmp?.nextBlock
                                }
                            } else {
                                fatalError("No block for attaching view!")
                            }
                            blockDropSoundPlayer?.play()
                        }
                    }
                }
            }
        default: ()
        }
    }
    
    @objc func handleDragBlockFromMenu (_ gesture: UIPanGestureRecognizer){
        //print("\(gesture.hash)")
        switch gesture.state {
        case .began:
            //print ("began")
            selectSoundPlayer?.play()
            if let gestureImageView = gesture.view as? UIImageView {
                let tempView = UIImageView(image: gestureImageView.image)
                tempView.frame = gestureImageView.frame
                tempView.center = gesture.location(in: self.view)
                self.view.addSubview(tempView)
                tempImageViews[gesture.hash] = tempView
            }
        case .changed:
            if let view = tempImageViews[gesture.hash] {
                let translation = gesture.translation(in: gesture.view)
                view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            }
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
        case .ended:
            //print ("ended")
            guard let id = gesture.view?.restorationIdentifier else {
                fatalError("Could not get id for new block.")
            }
            if let tempView = tempImageViews[gesture.hash] {
                tempView.removeFromSuperview()
                newBlock(typeString: id, view: tempView)
                tempImageViews[gesture.hash] = nil
            }
            //blockDropSoundPlayer?.play()
        default:
            print("default")
        }
    }
    

}

