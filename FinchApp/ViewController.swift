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
    
    //View for the workspace
    @IBOutlet weak var canvas: UIView!

    //So that we can change the look of the menu tabs to show what is selected/available
    @IBOutlet weak var motionTabButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var soundTabButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var colorTabButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var controlTabButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var controlTabButtonWidth: NSLayoutConstraint!
    
    //The views to show for each menu tab at each level
    @IBOutlet weak var tabsView: UIView! //super view of those below
    @IBOutlet weak var motionTabView: UIView!
    @IBOutlet weak var soundTabView: UIView!
    @IBOutlet weak var colorTabView: UIView!
    @IBOutlet weak var motionL2TabView: UIView!
    @IBOutlet weak var soundL2TabView: UIView!
    @IBOutlet weak var colorL2TabView: UIView!
    @IBOutlet weak var motionL3TabView: UIView!
    @IBOutlet weak var controlL3TabView: UIView!
    
    //Trash can
    @IBOutlet weak var trashImage: UIImageView!
    
    //Motion Menu Blocks
    @IBOutlet weak var moveForwardStatic: UIImageView!
    @IBOutlet weak var moveBackwardStatic: UIImageView!
    @IBOutlet weak var turnLeftStatic: UIImageView!
    @IBOutlet weak var turnRightStatic: UIImageView!
    @IBOutlet weak var moveForwardL2Static: UIImageView!
    @IBOutlet weak var moveBackwardL2Static: UIImageView!
    @IBOutlet weak var turnLeftL2Static: UIImageView!
    @IBOutlet weak var turnRightL2Static: UIImageView!
    @IBOutlet weak var moveStopL2Static: UIImageView!
    
    //Sound Menu Blocks
    @IBOutlet weak var soundStatic: UIImageView!
    @IBOutlet weak var soundL2Static: UIImageView!
    
    //Color Menu Blocks
    @IBOutlet weak var colorRedStatic: UIImageView!
    @IBOutlet weak var colorYellowStatic: UIImageView!
    @IBOutlet weak var colorGreenStatic: UIImageView!
    @IBOutlet weak var colorCyanStatic: UIImageView!
    @IBOutlet weak var colorBlueStatic: UIImageView!
    @IBOutlet weak var colorMagentaStatic: UIImageView!
    @IBOutlet weak var colorOffStatic: UIImageView!
    @IBOutlet weak var colorBlankStatic: UIImageView!
    @IBOutlet weak var colorOffL2Static: UIImageView!
    
    //Control Menu Blocks
    @IBOutlet weak var controlStartStatic: UIImageView!
    @IBOutlet weak var controlRepeatStatic: UIImageView!
    @IBOutlet weak var controlWaitStatic: UIImageView!
    
    //A dictionary to keep track of the ghost images that show up
    //as a block gets close enough to snap onto another
    var tempImageViews: [Int: UIImageView] = [:]
    
    //Take control of that top bar
    let topMenuViewController = TopMenuViewController()
    
    //Keep track of all the active blocks
    var workspaceBlocks:[UIImageView:Block] = [:] //moveable blocks that can make chains
    var menuBlocks:[UIImageView:Block] = [:] //these are static blocks in the menu.
    
    //What block will be executed when the user presses run in the top menu?
    var startBlock: Block?
    
    //What level are we currently on?
    var level: Int = 1
    
    //What tab is being shown now?
    var tabSelected: Tab = .motion
    
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
        if let blockDrop = NSDataAsset(name: "block-drop"),
            let select = NSDataAsset(name: "block-select and button-click"),
            let trash = NSDataAsset(name: "trash-sound") {
            do {
                try blockDropSoundPlayer = AVAudioPlayer(data: blockDrop.data)
                try selectSoundPlayer = AVAudioPlayer(data: select.data)
                try trashSoundPlayer = AVAudioPlayer(data: trash.data)
            } catch {
                print ("Could not load sound effects")
            }
        }
        
        //Make the canvas moveable
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        canvas.addGestureRecognizer(panGestureRecognizer)
        
        //Put the trash can out of sight for now
        self.view.sendSubview(toBack: trashImage)
        
        //Setup motion menu blocks
        setupMenuBlock(moveForwardStatic)
        setupMenuBlock(moveBackwardStatic)
        setupMenuBlock(turnLeftStatic)
        setupMenuBlock(turnRightStatic)
        setupMenuBlock(moveForwardL2Static)
        setupMenuBlock(moveBackwardL2Static)
        setupMenuBlock(turnLeftL2Static)
        setupMenuBlock(turnRightL2Static)
        setupMenuBlock(moveStopL2Static)
        
        //Setup sound menu blocks
        setupMenuBlock(soundStatic)
        setupMenuBlock(soundL2Static)
        
        //Setup color menu blocks
        setupMenuBlock(colorRedStatic)
        setupMenuBlock(colorYellowStatic)
        setupMenuBlock(colorGreenStatic)
        setupMenuBlock(colorCyanStatic)
        setupMenuBlock(colorBlueStatic)
        setupMenuBlock(colorMagentaStatic)
        setupMenuBlock(colorOffStatic)
        setupMenuBlock(colorBlankStatic)
        setupMenuBlock(colorOffL2Static)
        
        //Setup control menu blocks
        setupMenuBlock(controlStartStatic)
        setupMenuBlock(controlRepeatStatic)
        setupMenuBlock(controlWaitStatic)
        
        //Select the motion tab by default
        showMotionTab()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    //MARK: Button Actions
    
    @IBAction func showMotionTab() {
        motionTabButtonHeight.constant = 50
        soundTabButtonHeight.constant = 30
        colorTabButtonHeight.constant = 30
        controlTabButtonHeight.constant = 30
        
        tabSelected = .motion
        showTab()
    }
    
    @IBAction func showSoundTab() {
        motionTabButtonHeight.constant = 30
        soundTabButtonHeight.constant = 50
        colorTabButtonHeight.constant = 30
        controlTabButtonHeight.constant = 30
        
        tabSelected = .sound
        showTab()
    }
    
    @IBAction func showColorTab() {
        motionTabButtonHeight.constant = 30
        soundTabButtonHeight.constant = 30
        colorTabButtonHeight.constant = 50
        controlTabButtonHeight.constant = 30
        
        tabSelected = .color
        showTab()
    }

    @IBAction func showControlTab() {
        motionTabButtonHeight.constant = 30
        soundTabButtonHeight.constant = 30
        colorTabButtonHeight.constant = 30
        controlTabButtonHeight.constant = 50
        
        tabSelected = .control
        showTab()
    }
    
    //MARK: Top Menu Delegate methods
    
    func didPressNewProgramButton() {
        print("pressed new program")
        
        //Delete all blocks currently in the workspace
        for (_, block) in workspaceBlocks {
            deleteBlock(block)
        }
        
        //Creat a new start block
        //TODO: improve
        let startView = UIImageView(image: UIImage(named: "control-start"))
        startView.frame = CGRect(x: self.view.bounds.midX/2.0, y: 150.0, width: 91.0, height: 64.0)
        newBlock(typeString: "control-start", view: startView)
        if let tmp = workspaceBlocks[startView] {
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
        
        executeBlock(startBlock)
    }
    
    func didChangeLevel(to newLevel: Int) {
        print("Changed the level to \(newLevel)")
        level = newLevel
        didPressNewProgramButton()
        showTab()
    }
    
    //MARK: Gesture Recognizer Functions
    
    //Gesture to move the canvas around
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
            if let view = gesture.view as? UIImageView, let block = workspaceBlocks[view] {
                //if there is a block ahead of us on the chain, moving this block will change that
                block.detachPreviousBlock()
            }
            self.view.bringSubview(toFront: trashImage)
        case .changed:
            //find translation to offset by
            let translation = gesture.translation(in: gesture.view)
            if let view = gesture.view as? UIImageView {
                
                if isOverTrash(view) {
                    trashImage.image = UIImage(named: "trash-highlighted")
                } else {
                    trashImage.image = UIImage(named: "trash")
                }
                
                //view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
                guard let gestureBlock = workspaceBlocks[view] else {
                    fatalError("No block for panning view!")
                }
                
                var b : Block? = gestureBlock
                while let block = b {
                    block.imageView.center = CGPoint(x: block.imageView.center.x + translation.x, y: block.imageView.center.y + translation.y)
                    b = b?.nextBlock
                }
                
                var foundNeighbor = false
                for (bView,block) in workspaceBlocks {
                    if block.nextBlock == nil {
                        let bx = bView.center.x
                        let by = bView.center.y
                        if view.center.x > bx + 50 && view.center.x < bx + 100 && view.center.y > by - 60 && view.center.y < by + 60{
                            if tempImageViews[gesture.hash] == nil { //TODO: What if you are near 2 blocks?
                                let tmp = UIImageView(image: view.image)
                                tmp.alpha = 0.5
                                tmp.frame = view.frame
                                tmp.center = CGPoint(x: bx + block.offsetToNext + gestureBlock.offsetToPrevious, y: by - block.offsetY + gestureBlock.offsetY)
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
            
            //Get rid of the ghost image if there is one
            if let tmpView = tempImageViews[gesture.hash] {
                tmpView.removeFromSuperview()
                tempImageViews[gesture.hash] = nil
            }
            
            guard let view = gesture.view as? UIImageView else {
                fatalError("The view for this type of gesture should have been an image view.")
            }
            
            //Make the trash can disappear
            self.view.sendSubview(toBack: trashImage)
            //check to see if we are over the trash can and if so, delete blocks
            if isOverTrash(view) {
                trashImage.image = UIImage(named: "trash") //reset for next drag
                deleteBlockChain(startingWith: view)
                return
            }
            
            
            for (bView,block) in workspaceBlocks {
                if block.nextBlock == nil {
                    var bx = bView.center.x
                    var by = bView.center.y
                    if view.center.x > bx + 50 && view.center.x < bx + 100 && view.center.y > by - 60 && view.center.y < by + 60{
                        view.center = CGPoint(x: bx + 63, y: by)
                        if let b = workspaceBlocks[view] {
                            block.attachBlock(b)
                            var tmp : Block? = b
                            while let nextBlock = tmp {
                                guard let offsetX = nextBlock.previousBlock?.offsetToNext, let offsetY = nextBlock.previousBlock?.offsetY else {
                                    fatalError("There should be an offset to use here!")
                                }
                                nextBlock.imageView.center = CGPoint(x: bx + offsetX + nextBlock.offsetToPrevious, y: by - offsetY + nextBlock.offsetY)
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
    
    @objc func handleTapMenuBlock(_ gesture: UITapGestureRecognizer){
        guard let view = gesture.view as? UIImageView, let block = menuBlocks[view] else {
            fatalError("Could not find the menu block to execute!")
        }
        
        executeBlock(block)
    }
    
    //MARK: Other
    
    //Figure out which menu should be showing and what tabs should be available
    //based on what level and tab have been selected
    func showTab() {
        switch level {
        case 1:
            controlTabButtonWidth.constant = 0
            switch tabSelected {
            case .motion:
                tabsView.bringSubview(toFront: motionTabView)
            case .sound:
                tabsView.bringSubview(toFront: soundTabView)
            case .color:
                tabsView.bringSubview(toFront: colorTabView)
            case .control:
                showMotionTab()  //TODO: Test this
            }
        case 2:
            controlTabButtonWidth.constant = 0
            switch tabSelected {
            case .motion:
                tabsView.bringSubview(toFront: motionL2TabView)
            case .sound:
                tabsView.bringSubview(toFront: soundL2TabView)
            case .color:
                tabsView.bringSubview(toFront: colorL2TabView)
            case .control:
                showMotionTab()
            }
        case 3:
            controlTabButtonWidth.constant = 80
            switch tabSelected {
            case .motion:
                tabsView.bringSubview(toFront: motionL3TabView)
            case .sound:
                tabsView.bringSubview(toFront: soundL2TabView)
            case .color:
                tabsView.bringSubview(toFront: colorL2TabView)
            case .control:
                tabsView.bringSubview(toFront: controlL3TabView)
            }
        default:
            fatalError("Show tab for unrecognized level.")
        }
    }
    
    func setupMenuBlock(_ imageView: UIImageView){
        imageView.isUserInteractionEnabled = true
        
        //Add a gesture recognizer so that you can drag a new block from each menu block
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        imageView.addGestureRecognizer(gestureRecognizer)
        
        //Add a gesture recognizer so that you can tap a block to execute
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapMenuBlock(_:)))
        imageView.addGestureRecognizer(tapRecognizer)
        
        menuBlocks[imageView] = Block(withTypeFromString: imageView.restorationIdentifier ?? "unknown", withView: imageView)
    }
    
    func newBlock(typeString: String, view: UIImageView) {
        if workspaceBlocks[view] != nil{
            print("why does this view already have a block??")
        }
        
        //setup the view to be moveable
        view.isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleBlockPanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        //All this just to add a shadow
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        view.layer.shadowRadius = 1
        //view.layer.shouldRasterize = true
        
        canvas.addSubview(view)
        workspaceBlocks[view] = Block(withTypeFromString: typeString, withView: view)
    }
    
    func deleteBlockChain(startingWith view: UIImageView){
        guard let firstBlock = workspaceBlocks[view] else {
            fatalError("Why doesn't this view have a block attached to delete?")
        }
        
        trashSoundPlayer?.play()
        
        var nextBlock: Block? = firstBlock
        while let block = nextBlock {
            nextBlock = block.nextBlock
            deleteBlock(block)
        }
    }
    
    func deleteBlock(_ block: Block){
        block.imageView.removeFromSuperview()
        workspaceBlocks[block.imageView] = nil
    }
    
    //TODO: improve this function
    func executeBlock(_ block: Block){
        guard let finchID = topMenuViewController.finchID else {
            print("No robot selected, nothing to run on.")
            return
        }
        
        if topMenuViewController.isConnected {
            guard let finch = BLECentralManager.shared.robotForID(finchID) as? FinchPeripheral else {
                print("Could not find finch for id given. Can not run program.")
                return
            }
            block.execute(on: finch)
        } else {
            print ("Cannot run if robot is not connected.")
        }
    }
    
    func isOverTrash(_ view: UIImageView) -> Bool{
        //print("\(view.center.x) \(trashImage.center.x) \(view.center.y) \(trashImage.center.y)")
        if view.center.x > trashImage.center.x - 50.0 &&
            view.center.x < trashImage.center.x + 50.0 &&
            view.center.y > trashImage.center.y - 55.0 &&
            view.center.y < trashImage.center.y + 55.0 {
            return true
        } else {
            return false
        }
    }
}

enum Tab {
    case motion
    case sound
    case color
    case control
}

