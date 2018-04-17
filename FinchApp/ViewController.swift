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
    var ghostImageViews: [Int: UIImageView] = [:]
    //A dictionary to keep track of temporary blocks created
    //as a block is dragged from the menu
    var tempBlocks: [Int: Block] = [:]
    
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
    
    //A dispatch queue so that blocks can be executed without blocking the UI
    let serialExecutionQueue = DispatchQueue(label: "blockExecutionQueue")

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
        
        //Make the canvas moveable, give it an initial size
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCanvasPanGesture(_:)))
        canvas.addGestureRecognizer(panGestureRecognizer)
        canvas.frame = self.view.frame
        
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
        
        //Start off with a start block
        addStartBlock()
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
        //When the start block is deleted, a new one will be created
        for (_, block) in workspaceBlocks {
            deleteBlock(block)
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
    @objc func handleCanvasPanGesture (_ gesture: UIPanGestureRecognizer) {
        if (gesture.state == UIGestureRecognizerState.changed) {
            //find translation to offset by
            let translation = gesture.translation(in: gesture.view)
            if let view = gesture.view {
                view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
                
                //Make sure the canvas covers the whole screen still
                if !view.frame.contains(self.view.bounds){
                    resizeCanvas()
                }
            }
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
        }
    }
    
    @objc func handleBlockPanGesture (_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            selectSoundPlayer?.play()
            self.view.bringSubview(toFront: trashImage)
            if let view = gesture.view as? UIImageView, let block = workspaceBlocks[view] {
                //if there is a block ahead of us on the chain, moving this block will change that
                block.detachPreviousBlock()
                block.bringToFront()
            }
            
        case .changed:
            //find the view and the translation to offset by
            let translation = gesture.translation(in: gesture.view)
            guard let view = gesture.view as? UIImageView else {
                    fatalError("This gesture should only be attached to an image view")
            }
                
            //Highlight the trash if we are over it
            if isOverTrash(view) {
                trashImage.isHighlighted = true
            } else {
                trashImage.isHighlighted = false
            }
            
            //Move each block in the chain by the translation amount
            guard let gestureBlock = workspaceBlocks[view] else {
                fatalError("No block for panning view!")
            }
            gestureBlock.imageView.center = CGPoint(x: gestureBlock.imageView.center.x + translation.x, y: gestureBlock.imageView.center.y + translation.y)
            gestureBlock.positionChainImages()
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
            
            //Look for a block that could be connected to and produce a ghost image
            if let attachableBlock = blockAttachable(to: gestureBlock) {
                addGhostImage(of: view, at: gestureBlock.centerPosition(whenConnectingTo: attachableBlock), forGesture: gesture.hash)
            } else {
                removeGhostImage(forGesture: gesture.hash)
            }
            
            
        case .ended:
            //Get rid of the ghost image if there is one
            removeGhostImage(forGesture: gesture.hash)
            
            guard let view = gesture.view as? UIImageView else {
                fatalError("The view for this type of gesture should have been an image view.")
            }
            
            //Make the trash can disappear
            self.view.sendSubview(toBack: trashImage)
            //check to see if we are over the trash can and if so, delete blocks
            if isOverTrash(view) {
                trashImage.isHighlighted = false //reset for next drag
                deleteBlockChain(startingWith: view)
                return
            }
            
            //Look for a block to attach to and attach if possible
            guard let gestureBlock = workspaceBlocks[view] else {
                fatalError("No block for panning view!")
            }
            if let attachBlock = blockAttachable(to: gestureBlock) {
                attachBlock.attachBlock(gestureBlock)
                blockDropSoundPlayer?.play()
            }
            
        default: ()
        }
    }
    
    @objc func handleDragBlockFromMenu (_ gesture: UIPanGestureRecognizer){
        
        switch gesture.state {
        case .began:
            selectSoundPlayer?.play()
            guard let gestureImageView = gesture.view as? UIImageView else {
                fatalError("The view for this gesture should be an image view.")
            }
            guard let id = gesture.view?.restorationIdentifier else {
                fatalError("Could not get id for new block.")
            }
            
            let tempView = UIImageView(image: gestureImageView.image)
            tempView.frame = gestureImageView.frame
            tempView.center = gesture.location(in: self.view)
            self.view.addSubview(tempView)
            let tempBlock = Block(withTypeFromString: id, withView: tempView)
            tempBlocks[gesture.hash] = tempBlock
            
        case .changed:
            guard let tempBlock = tempBlocks[gesture.hash] else {
                fatalError("there should be a temp block here")
            }

            //do the translation
            let translation = gesture.translation(in: gesture.view)
            tempBlock.imageView.center = CGPoint(x: tempBlock.imageView.center.x + translation.x, y: tempBlock.imageView.center.y + translation.y)
            gesture.setTranslation(CGPoint.zero, in: gesture.view)
            
            //Look for a block that could be connected to and produce a ghost image
            if let attachableBlock = blockAttachable(to: tempBlock) {
                addGhostImage(of: tempBlock.imageView, at: tempBlock.centerPosition(whenConnectingTo: attachableBlock), forGesture: gesture.hash)
            } else {
                removeGhostImage(forGesture: gesture.hash)
            }
            
        case .ended:
            removeGhostImage(forGesture: gesture.hash)
            
            guard let tempBlock = tempBlocks[gesture.hash] else {
                fatalError("there should be a temp block here")
            }
            
            tempBlock.imageView.removeFromSuperview()
            tempBlocks[gesture.hash] = nil
            
            // if the block is dropped back onto the menu, discard
            // otherwise add to workspace
            if tabsView.frame.origin.y > tempBlock.imageView.frame.origin.y {
                addBlockToWorkspace(tempBlock)
                if let attachBlock = blockAttachable(to: tempBlock) {
                    attachBlock.attachBlock(tempBlock)
                    blockDropSoundPlayer?.play()
                }
            }
            
        default: ()
        }
    }
    
    @objc func handleTapBlock(_ gesture: UITapGestureRecognizer){
        guard let view = gesture.view as? UIImageView else {
            fatalError("Could not find the view for the gesture?!")
        }
        
        if let block = menuBlocks[view] {
            executeBlock(block)
        } else if let block = workspaceBlocks[view] {
            executeBlock(block)
        } else {
            fatalError("Could not find block to execute!")
        }
    }
    
    
    //MARK: Methods for dealing with blocks
    
    func setupMenuBlock(_ imageView: UIImageView){
        imageView.isUserInteractionEnabled = true
        
        //Add a gesture recognizer so that you can drag a new block from each menu block
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
        imageView.addGestureRecognizer(gestureRecognizer)
        
        //Add a gesture recognizer so that you can tap a block to execute
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapBlock(_:)))
        imageView.addGestureRecognizer(tapRecognizer)
        
        menuBlocks[imageView] = Block(withTypeFromString: imageView.restorationIdentifier ?? "unknown", withView: imageView)
    }
    

    func addBlockToWorkspace(_ block: Block) {
        
        let view = block.imageView
        
        if workspaceBlocks[view] != nil{
            print("why does this view already have a block??")
        }
        
        //setup the view to be moveable
        view.isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleBlockPanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        //Add a gesture recognizer so that you can tap a block to execute
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapBlock(_:)))
        view.addGestureRecognizer(tapRecognizer)
        
        //All this just to add a shadow
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        view.layer.shadowRadius = 1
        //view.layer.shouldRasterize = true //TODO: maybe rasterize?
        
        //put the image view in the coordinate system of the canvas and add
        view.frame.origin.x = view.frame.origin.x - canvas.frame.origin.x
        view.frame.origin.y = view.frame.origin.y - canvas.frame.origin.y
        canvas.addSubview(view)
        workspaceBlocks[view] = block
    }
    
    func addStartBlock() {
        print("Adding start block")
        //Creat a new start block
        //TODO: improve
        let startView = UIImageView(image: UIImage(named: "control-start"))
        startView.frame = CGRect(x: self.view.bounds.midX/4.0, y: 150.0, width: 91.0, height: 64.0)
        startBlock = Block(withTypeFromString: "control-start", withView: startView)
        addBlockToWorkspace(startBlock!)
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
        if block == startBlock { addStartBlock() } //if we delete the start block, add a new one
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
            serialExecutionQueue.async {
                block.execute(on: finch)
            }
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
    
    //This function returns the block in the workspace that the block
    //should attach to if dropped (or nil if not close enough to any)
    //Should probably find the closest, but this isn't usually an issue
    //TODO: make sure you never return the same block?
    func blockAttachable (to block: Block) -> Block? {
        var xOffset: CGFloat = 0.0
        var yOffset: CGFloat = 0.0
        //if this block hasn't been added to the workspace yet,
        //must offset by canvas position
        if workspaceBlocks[block.imageView] == nil {
            xOffset = canvas.frame.origin.x
            yOffset = canvas.frame.origin.y
        }
        
        var attachBlock: Block? = nil
        if block.type != .controlStart { //controlStart does not snap to anything
            for (_, workspaceBlock) in workspaceBlocks {
                let minX = workspaceBlock.imageView.center.x + workspaceBlock.offsetToNext + block.offsetToPrevious - 10.0 + xOffset
                let maxX = workspaceBlock.imageView.center.x + workspaceBlock.offsetToNext + block.offsetToPrevious + block.imageView.frame.width / 2.0 + xOffset
                let minY = workspaceBlock.imageView.center.y - block.imageView.frame.height + yOffset
                let maxY = workspaceBlock.imageView.center.y + block.imageView.frame.height + yOffset
                //if workspaceBlock.nextBlock == nil && block.isInAttachSpace(of: workspaceBlock){
                if workspaceBlock.nextBlock == nil &&
                    block.imageView.center.x > minX && block.imageView.center.x < maxX &&
                    block.imageView.center.y > minY && block.imageView.center.y < maxY{
                    attachBlock = workspaceBlock
                // If this is a repeat block, also check if this can be connected as a sub block
                } else if workspaceBlock.type == .controlRepeat {
                    let minX = workspaceBlock.imageView.center.x - 20.0 + xOffset
                    let maxX = workspaceBlock.imageView.center.x + xOffset
                    let minY = workspaceBlock.imageView.center.y - workspaceBlock.offsetY - block.imageView.frame.height + yOffset
                    let maxY = workspaceBlock.imageView.center.y - workspaceBlock.offsetY + block.imageView.frame.height + yOffset
                    if workspaceBlock.blockChainToRepeat == nil &&
                        block.imageView.center.x > minX && block.imageView.center.x < maxX &&
                        block.imageView.center.y > minY && block.imageView.center.y < maxY{
                        attachBlock = workspaceBlock
                    }
                }
            }
        }
        return attachBlock
    }
    
    //MARK: Other
    
    //TODO: maybe make it so that some block has to be on the screen?
    func resizeCanvas() {
        if canvas.frame.origin.y > self.view.bounds.origin.y {
            canvas.frame.origin.y = 0
        } else if canvas.frame.origin.y + canvas.frame.size.height < self.view.bounds.size.height {
            canvas.frame.size.height = self.view.bounds.size.height - canvas.frame.origin.y
        }
        
        if canvas.frame.origin.x > self.view.bounds.origin.x {
            canvas.frame.origin.x = 0
        } else if canvas.frame.origin.x + canvas.frame.size.width < self.view.bounds.size.width {
            canvas.frame.size.width = self.view.bounds.size.width - canvas.frame.origin.x
        }
    }
    
    func addGhostImage (of view: UIImageView, at position: CGPoint, forGesture hash: Int) {
        if ghostImageViews[hash] == nil {
            //let tmp = UIImageView(image: view.image)
            //tmp.alpha = 0.5
            
            let tmpImage = view.image?.withRenderingMode(.alwaysTemplate)
            let tmp = UIImageView(image: tmpImage)
            tmp.tintColor = UIColor.lightGray
            
            tmp.frame = view.frame
            tmp.center = position
            canvas.addSubview(tmp)
            canvas.sendSubview(toBack: tmp)
            ghostImageViews[hash] = tmp
        }
    }
    func removeGhostImage (forGesture hash: Int) {
        if let tmp = ghostImageViews[hash] {
            tmp.removeFromSuperview()
            ghostImageViews[hash] = nil
        }
    }
    
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
}

enum Tab {
    case motion
    case sound
    case color
    case control
}

