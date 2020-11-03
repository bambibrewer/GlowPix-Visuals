//
//  Block.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import Foundation
import UIKit

class Block: NSObject, UIPopoverPresentationControllerDelegate {
    
    let executionDuration: UInt32 //The amount of time the block will sleep during execution
    
    let type: BlockType
    let group: BlockGroup
    let imageView: UIImageView
   
   let blockHeight:CGFloat = 80
   let originalBlockWidth: CGFloat = 261.1
//   var originalBlockWidth: CGFloat {
//      get {
//         let originalBlockRatio = 346.0/104.0
//         return CGFloat(originalBlockRatio)*blockHeight
//      }
//   }
    var offsetToNext: CGFloat //The distance along the x axis to place the next block.
    var offsetToPrevious: CGFloat //The distance along the x axis to place the previous block
    let offsetY: CGFloat //The offset on the y axis for blocks that have a text field making them taller
    
    var nextBlock: Block? //the block to be executed after this one
    var previousBlock: Block? //block before this one on chain
    var inputField: UITextField? //Only on certain blocks
    
    //Only on level 2 (and 3?) color block
    var colorPickerButton: UIButton?
    var colorBulbImage: UIImageView?
    
    //Only for repeat blocks
    var blockChainToRepeat: Block?
    var currentWidth: CGFloat //for stretching
    let originalWidth: CGFloat
    
    init(withTypeFromString t: String, withView i: UIImageView) {
        
        type = BlockType.getType(fromString: t)
        imageView = i
      print(imageView.frame)
      imageView.frame = CGRect(x: imageView.frame.origin.x,y: imageView.frame.origin.y, width: self.originalBlockWidth, height: self.blockHeight)
      print(imageView.frame)
        originalWidth = i.frame.width
        currentWidth = i.frame.width
        
        //Set how long the block will be executed for
      
      executionDuration = 1000000
        
        //Set the block's offsets so that other block link up properly
        switch type {
        case .controlStart:
            offsetToNext = 27.0
            offsetToPrevious = 0.0 //Should never be a previous block for the start block
            offsetY = 0.0
        case .controlRepeat:
            offsetToNext = 73.0
            offsetToPrevious = 73.0
            offsetY = -2.0
        case .moveForwardL2, .moveBackwardL2, .turnRightL2, .turnLeftL2,
             .controlWait:
            offsetToNext = 32.0
            offsetToPrevious = 32.0
            offsetY = 4.0
        default:
         offsetToNext = 0.4*blockHeight
         offsetToPrevious = 0.4*blockHeight
            offsetY = 0.0
        }
        
        //Set the group for the block
        switch type {
        case .controlStart, .controlRepeat, .controlWait:
            group = .control
        case .colorRed, .colorYellow, .moveForwardL1, .moveForwardL2, .moveBackwardL1, .moveBackwardL2,
             .turnRightL1, .turnRightL2, .turnLeftL1, .turnLeftL2, .moveStopL2:
            group = .motion
        }
        
        //Setup the input field for blocks that need it
        switch type {
        case .controlRepeat, .controlWait, .moveForwardL2, .moveBackwardL2,
             .turnLeftL2, .turnRightL2:
            var origin = CGPoint(x: 19.0, y: 57.0)
            if type == .controlRepeat {
                origin = CGPoint(x: 106.0, y: 68.0)
            }
            let size = CGSize(width: 28.0, height: 15.0)
            inputField = UITextField(frame: CGRect(origin: origin, size: size))
            //inputField?.borderStyle = .bezel //for testing it can be useful to be able to see the border
            inputField?.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .caption1), size: 10.0)
            inputField?.textAlignment = .center
            imageView.addSubview(inputField!)
        default: ()
        }
        
        super.init()
    }
    
    
    
    //MARK: Other
    
    func centerPosition(whenConnectingTo block: Block ) -> CGPoint {
      let X = block.imageView.center.x + self.offsetY//block.offsetToNext + self.offsetToPrevious
      let Y = block.imageView.center.y + block.offsetToNext + self.offsetToPrevious//- block.offsetY + self.offsetY
        
        return CGPoint(x: X, y: Y)
    }
    func centerPosition(whenInsertingInto block: Block ) -> CGPoint {
        let X = block.imageView.frame.origin.x + 34.0 + self.offsetToPrevious
        let Y = block.imageView.center.y - block.offsetY + self.offsetY
        
        return CGPoint(x: X, y: Y)
    }
    
    //Attach a block chain to the back of this one
    func attachBlock (_ b: Block){
        print("attach block")
    
        if let nextBlock = nextBlock {
            b.attachToChain(nextBlock)
        }
        nextBlock = b
        b.previousBlock = self
        b.resizeRepeatBlocks()
        positionChainImages()
    }
    //Insert a block into this one (only for repeat blocks)
    func insertBlock (_ b: Block){
        print("insert block")
        if type != .controlRepeat {
            fatalError("insert block should only be called for repeat blocks")
        }
        
        if let blockChainToRepeat = blockChainToRepeat {
            b.attachToChain(blockChainToRepeat)
        }
        blockChainToRepeat = b
        b.previousBlock = self
        b.resizeRepeatBlocks()
        positionChainImages()
    }
    
    //attach block b to the end of this chain
    func attachToChain (_ b: Block){
        if nextBlock == nil {
            nextBlock = b
            b.previousBlock = self
        } else {
            nextBlock?.attachToChain(b)
        }
    }
    
    func chainWidth() -> CGFloat {
        return offsetToNext + offsetToPrevious + (nextBlock?.chainWidth() ?? 0.0)
    }
    
    //Put into position all of the images of a chain connecting to this one
    func positionChainImages(){
        //print("position chain images")
        if let nextBlock = nextBlock {
            nextBlock.imageView.center = nextBlock.centerPosition(whenConnectingTo: self)
            nextBlock.positionChainImages()
        }
        if let repeater = blockChainToRepeat {
            repeater.imageView.center = repeater.centerPosition(whenInsertingInto: self)
            repeater.positionChainImages()
        }
    }
    
    //Look above for a repeat block that needs to be resized
    func resizeRepeatBlocks() {
        print("resize repeat blocks")
        if let previousBlock = previousBlock {
            if previousBlock.type == .controlRepeat && previousBlock.blockChainToRepeat == self {
                previousBlock.resize()
                previousBlock.positionChainImages()
            }
            previousBlock.resizeRepeatBlocks()
        }
    }
    
    func resize() {
        print("resize")
        //right now, control repeat is the only block to resize
        if type != .controlRepeat {
            return
        }
        
        var width = originalWidth
        if let chainWidth = blockChainToRepeat?.chainWidth() {
            width = chainWidth + 99.0
        }
        let deltaWidth = width - originalWidth
        
        offsetToPrevious = 73.0 + deltaWidth / 2.0
        offsetToNext = 73.0 + deltaWidth / 2.0
        inputField?.frame.origin.x = 106.0 + deltaWidth
        imageView.frame = CGRect(x: imageView.frame.origin.x, y: imageView.frame.origin.y, width: width, height: imageView.frame.height)
    }
    
    func detachPreviousBlock(){
        print("detach")
        if previousBlock?.blockChainToRepeat == self {
            previousBlock?.blockChainToRepeat = nil
            previousBlock?.resize()
            previousBlock?.positionChainImages()
        }else{
            previousBlock?.nextBlock = nil
        }
        previousBlock?.resizeRepeatBlocks()
        previousBlock = nil
    }
    
    //Bring the image views to the front so that the last in the chain is on top
    func bringToFront() {
        imageView.superview?.bringSubview(toFront: imageView)
        blockChainToRepeat?.bringToFront()
        nextBlock?.bringToFront()
    }
    
}

enum BlockGroup {
    case control
    case motion
}

enum BlockType {
    //Control (Level 3 only except start)
    case controlStart
    case controlRepeat
    case controlWait
    //Motion Level 1
    case moveBackwardL1
    case moveForwardL1
    case turnLeftL1
    case turnRightL1
    //Motion Level 2
    case moveBackwardL2
    case moveForwardL2
    case moveStopL2
    case turnLeftL2
    case turnRightL2
    //Motion Level 3 - still waiting on graphics
    //Color Level 1
  
    case colorRed
    case colorYellow
  
    
    
    static func getType(fromString string: String) -> BlockType{
        switch string {
        //Control (Level 3 only)
        case "control-start":
            return .controlStart
        case "repeat-x-times":
            return .controlRepeat
        case "wait":
            return .controlWait
        //Motion Level 1
        case "move-forward":
            return .moveForwardL1
        case "move-backward":
            return .moveBackwardL1
        case "turn-left":
            return .turnLeftL1
        case "turn-right":
            return .turnRightL1
        //Motion Level 2
        case "move-forward-L2":
            return .moveForwardL2
        case "move-backward-L2":
            return .moveBackwardL2
        case "turn-left-L2":
            return .turnLeftL2
        case "turn-right-L2":
            return .turnRightL2
        case "move-stop":
            return .moveStopL2
        //Motion Level 3 - still waiting on graphics
        //Sound All Levels
      
        //Color Level 1
        case "color-red":
            return .colorRed
        case "color-yellow":
            return .colorYellow
        default:
            fatalError("Unknown block type \(string)!")
        }
    }
}
