//
//  ViewController.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
   //var invisibleButtonForAnchor: UIButton?
   
   
   //View for the workspace
   @IBOutlet weak var canvas: UIView!
   
   @IBOutlet var menuView: UIView!
   // Menu Blocks
   @IBOutlet var additionBlock: UIImageView!
   @IBOutlet var subtractionBlock: UIImageView!
   @IBOutlet var doubleAdditionBlock: UIImageView!
   @IBOutlet var additionNestedBlock: UIImageView!
   
   
   //A dictionary to keep track of the ghost images that show up
   //as a block gets close enough to snap onto another
   var ghostImageViews: [Int: UIImageView] = [:]
   //A dictionary to keep track of temporary blocks created
   //as a block is dragged from the menu
   var tempBlocks: [Int: Block] = [:]
   
   
   //Keep track of all the active blocks
   var workspaceBlocks:[UIImageView:Block] = [:] //moveable blocks that can make chains
   //var menuBlocks:[UIImageView:Block] = [:] //these are static blocks in the menu.
   
   //What block will be executed when the user presses run in the top menu?
   //TODO: do we need this for level 3?
   var startBlock: Block?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      
      //Make the canvas moveable, give it an initial size
      let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCanvasPanGesture(_:)))
      canvas.addGestureRecognizer(panGestureRecognizer)
      canvas.frame = self.view.frame
      
      
      //Setup color menu blocks
      menuView.isHidden = false
      setupMenuBlock(additionBlock)
      setupMenuBlock(subtractionBlock)
      setupMenuBlock(doubleAdditionBlock)
      
      //Setup control menu blocks
      setupMenuBlock(additionNestedBlock)
      
      
      //Start off with a start block
      addStartBlock()
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
   }
   
   
   
   //MARK: Gesture Recognizer Functions
   
   //Gesture to move the canvas around
   @objc func handleCanvasPanGesture (_ gesture: UIPanGestureRecognizer) {
      if (gesture.state == UIGestureRecognizer.State.changed) {
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
         

         //Move each block in the chain by the translation amount
         guard let gestureBlock = workspaceBlocks[view] else {
            fatalError("No block for panning view!")
         }
         gestureBlock.imageView.center = CGPoint(x: gestureBlock.imageView.center.x + translation.x, y: gestureBlock.imageView.center.y + translation.y)
         gestureBlock.positionChainImages()
         gesture.setTranslation(CGPoint.zero, in: gesture.view)
         
         //Look for a block that could be connected to and produce a ghost image
         addGhostImageOrNestTarget(gestureBlock, gesture)
         
      case .ended:
         //Get rid of the ghost image if there is one
         removeGhostImage(forGesture: gesture.hash)
         
         guard let view = gesture.view as? UIImageView else {
            fatalError("The view for this type of gesture should have been an image view.")
         }
         
         // if the block is dropped back onto the menu, discard it
         if view.frame.origin.x < menuView.frame.maxX - 10 {
            deleteBlockChain(startingWith: view)
            return
         }
         
         //Look for a block to attach to and attach if possible
         guard let gestureBlock = workspaceBlocks[view] else {
            fatalError("No block for panning view!")
         }
         if (gestureBlock.isNestable) {
            if let targetButton = targetForNestedBlock(block: gestureBlock) {
               print("this is where we would do nesting")
               // where repeatBlockToInsert was
            }
         } else if let attachBlock = blockAttachable(to: gestureBlock) {
            attachBlock.attachBlock(gestureBlock)
         }
         
      default: ()
      }
   }
   
   
   
   @objc func handleDragBlockFromMenu (_ gesture: UIPanGestureRecognizer){
      
      switch gesture.state {
      case .began:
         guard let gestureImageView = gesture.view as? UIImageView else {
            fatalError("The view for this gesture should be an image view.")
         }
         guard let id = gesture.view?.restorationIdentifier else {
            fatalError("Could not get id for new block.")
         }
         print(id)
         
         var tempView = UIImageView()
         if id == "additionLevel5" {
            tempView = UIImageView(image: UIImage(named: "testblock")?.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)))
         } else {
            tempView = UIImageView(image: UIImage(named: "glowpix-block-white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 50, bottom: 25, right: 10)))
         }
         //UIImageView(image: gestureImageView.image)
         //tempView.frame = gestureImageView.frame    // Set frame using block height
         tempView.center = gesture.location(in: self.view)
         self.view.addSubview(tempView)
         print("stashing block")
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
         
         addGhostImageOrNestTarget(tempBlock, gesture)
         
      case .ended:
         removeGhostImage(forGesture: gesture.hash)
         
         guard let tempBlock = tempBlocks[gesture.hash] else {
            fatalError("there should be a temp block here")
         }
         
         tempBlock.imageView.removeFromSuperview()
         tempBlocks[gesture.hash] = nil
         
         // if the block is dropped back onto the menu, discard
         // otherwise add to workspace
         print("menu \(menuView.frame.maxX) and other \(tempBlock.imageView.frame.origin.x)")
         if menuView.frame.maxX < tempBlock.imageView.frame.origin.x {
            addBlockToWorkspace(tempBlock)
            
            if (tempBlock.isNestable) {
               if let targetButton = targetForNestedBlock(block: tempBlock) {
                  print("this is where we would do nesting")
                  // where repeatBlockToInsert was
               }
            } else if let attachBlock = blockAttachable(to: tempBlock) {
               attachBlock.attachBlock(tempBlock)
            }
         }
         
      default: ()
      }
   }
   
   
   
   //MARK: Methods for dealing with blocks
   
   func setupMenuBlock(_ imageView: UIImageView){
      imageView.isUserInteractionEnabled = true
      
      //Add a gesture recognizer so that you can drag a new block from each menu block
      let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDragBlockFromMenu(_:)))
      imageView.addGestureRecognizer(gestureRecognizer)
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
      
      
      //All this just to add a shadow
      view.layer.shadowColor = UIColor.lightGray.cgColor
      view.layer.shadowOpacity = 1
      view.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
      view.layer.shadowRadius = 1
      
      //put the image view in the coordinate system of the canvas and add
      view.frame.origin.x = view.frame.origin.x - canvas.frame.origin.x
      view.frame.origin.y = view.frame.origin.y - canvas.frame.origin.y
      canvas.addSubview(view)
      workspaceBlocks[view] = block
   }
   
   func addStartBlock() {
      //Creat a new start block
      //TODO: improve
      let startView = UIImageView(image: UIImage(named: "glowpix-start"))
      startView.frame = CGRect(x: self.view.bounds.midX/2.0, y: 150.0, width: 91.0, height: 64.0)
      startBlock = Block(withTypeFromString: "start", withView: startView)
      addBlockToWorkspace(startBlock!)
   }
   
   func deleteBlockChain(startingWith view: UIImageView){
      guard let firstBlock = workspaceBlocks[view] else {
         fatalError("Why doesn't this view have a block attached to delete?")
      }
      deleteBlockChain(startingWith: firstBlock)
   }
   
   func deleteBlockChain(startingWith block: Block?) {
      if let block = block {
         deleteBlockChain(startingWith: block.nextBlock)
         deleteBlockChain(startingWith: block.blockChainToRepeat)
         deleteBlock(block)
      }
   }
   
   func deleteBlock(_ block: Block){
      if block == startBlock { addStartBlock() } //if we delete the start block, add a new one
      block.imageView.removeFromSuperview()
      workspaceBlocks[block.imageView] = nil
   }
   
   
   //This function returns the block in the workspace that the block
   //should attach to if dropped (or nil if not close enough to any)
   //Should probably find the closest, but this isn't usually an issue
   func blockAttachable (to block: Block) -> Block? {
      let offset = canvasOffset(of: block)
      
      var attachBlock: Block? = nil
      if (block.type != .startBlock) && !block.isNestable { // start block and nestable blocks do not snap to anything
         for (_, workspaceBlock) in workspaceBlocks {
            if workspaceBlock != block {
               
               let minX = workspaceBlock.imageView.center.x - block.imageView.frame.width  + offset.x
               let maxX = workspaceBlock.imageView.center.x + block.imageView.frame.width  + offset.x
               let minY = workspaceBlock.imageView.center.y + workspaceBlock.offsetToNext + block.offsetToPrevious - 10.0  + offset.y
               let maxY = workspaceBlock.imageView.center.y + workspaceBlock.offsetToNext + block.offsetToPrevious + block.imageView.frame.height / 2.0 + offset.y
               
               if block.imageView.center.x > minX && block.imageView.center.x < maxX &&
                     block.imageView.center.y > minY && block.imageView.center.y < maxY{
                  attachBlock = workspaceBlock
               }
            }
         }
      }
      return attachBlock
   }
   
   // Return any button in a block that could be replaced with a nested block
   func targetForNestedBlock(block: Block) -> UIButton? {
      let offset = canvasOffset(of: block)

      for (_, workspaceBlock) in workspaceBlocks {
         if workspaceBlock.isNestable && workspaceBlock != block{
            for targetButton in [workspaceBlock.firstNumber, workspaceBlock.secondNumber] {
               let minX = workspaceBlock.imageView.frame.origin.x + targetButton.frame.minX + offset.x
               let maxX = workspaceBlock.imageView.frame.origin.x + targetButton.frame.maxX + offset.x
               let minY = workspaceBlock.imageView.frame.origin.y + targetButton.frame.minY + offset.y
               let maxY = workspaceBlock.imageView.frame.origin.y + targetButton.frame.maxY + offset.y
               if (block.imageView.frame.minX < maxX && block.imageView.frame.minX > minX && block.imageView.frame.minY < maxY && block.imageView.frame.minY > minY) || (block.imageView.frame.minX < maxX && block.imageView.frame.minX > minX && block.imageView.frame.maxY < maxY && block.imageView.frame.maxY > minY) {
                  return targetButton
               }
            }
         }
      }
      return nil
   }
   
   //return any repeat block that block can be inserted into
   func repeatBlockToInsert(block: Block) -> Block? {
      let offset = canvasOffset(of: block)
      let minInsertX: CGFloat = 20.0
      
      var repeater: Block? = nil
      for (_, workspaceBlock) in workspaceBlocks {
         if workspaceBlock.type == .additionLevel5 && workspaceBlock != block{
            let minX = workspaceBlock.imageView.frame.origin.x + minInsertX + offset.x
            let maxX = workspaceBlock.imageView.frame.origin.x + minInsertX + block.offsetToPrevious + offset.x
            let minY = workspaceBlock.imageView.frame.origin.y - block.imageView.frame.height + offset.y
            let maxY = workspaceBlock.imageView.frame.origin.y + block.imageView.frame.height + offset.y
            if block.imageView.frame.origin.x < maxX && block.imageView.frame.origin.x > minX && block.imageView.frame.origin.y < maxY && block.imageView.frame.origin.y > minY {
               repeater = workspaceBlock
            }
         }
      }
      return repeater
   }
   
   //MARK: Other
   
   //returns the point of the canvas origin if the block is not yet part of the
   //workspace, 0 otherwise
   func canvasOffset(of block: Block) -> CGPoint {
      var xOffset: CGFloat = 0.0
      var yOffset: CGFloat = 0.0
      //if this block hasn't been added to the workspace yet,
      //must offset by canvas position
      if workspaceBlocks[block.imageView] == nil {
         xOffset = canvas.frame.origin.x
         yOffset = canvas.frame.origin.y
      }
      return CGPoint(x: xOffset, y: yOffset)
   }
   
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
   
   fileprivate func addGhostImageOrNestTarget(_ tempBlock: Block, _ gesture: UIPanGestureRecognizer) {
      //Look for a block that could be connected to and produce a ghost image
      if (tempBlock.isNestable) {
         if let targetButton = targetForNestedBlock(block: tempBlock) {
            targetButton.backgroundColor = UIColor.lightGray
         } else {
            removeShadedButtons()
         }
      } else if let attachableBlock = blockAttachable(to: tempBlock) {
         addGhostImage(of: tempBlock.imageView, at: tempBlock.getPositionForGhost(whenConnectingTo: attachableBlock), forGesture: gesture.hash)
      } else {
         removeGhostImage(forGesture: gesture.hash)
      }
   }
   
   fileprivate func addGhostImage (of view: UIImageView, at position: CGPoint, forGesture hash: Int) {
      //if ghostImageViews[hash] == nil { //would like to only create a ghost if there isn't one, but it seems that some attachment zones can overlap. mostly a problem of the repeat block.
      //let tmp = UIImageView(image: view.image)
      //tmp.alpha = 0.5
      
      removeGhostImage(forGesture: hash)
      
      let tmpImage = view.image?.withRenderingMode(.alwaysTemplate)
      let tmp = UIImageView(image: tmpImage)
      tmp.tintColor = UIColor.lightGray
      
      tmp.frame = view.frame
      tmp.frame.origin.x = position.x
      tmp.center.y = position.y
      canvas.addSubview(tmp)
      ghostImageViews[hash] = tmp
   }
   
   fileprivate func removeGhostImage (forGesture hash: Int) {
      if let tmp = ghostImageViews[hash] {
         tmp.removeFromSuperview()
         ghostImageViews[hash] = nil
      }
   }
   
   fileprivate func removeShadedButtons() {
      for (_, workspaceBlock) in workspaceBlocks {
         if workspaceBlock.isNestable {
            for targetButton in [workspaceBlock.firstNumber, workspaceBlock.secondNumber] {
               targetButton.backgroundColor = UIColor.white
            }
         }
      }
   }
}

