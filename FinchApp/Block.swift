//
//  Block.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import Foundation
import UIKit

class Block: NSObject, KeyPadPopupDelegate {
   
   func numberChanged(number: Int?) {
      if let num = number {
         selectedButton?.setTitle(String(num), for: .normal)
         selectedButton?.sizeToFit()
         
         // If it is a large number, we need to resize all the other stuff
         print(selectedButton?.frame.size.width)
      }
   }
   
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
   var offsetToNext: CGFloat //The distance along the y axis to place the next block.
   var offsetToPrevious: CGFloat //The distance along the y axis to place the previous block
   let offsetX: CGFloat //The offset on the x axis for blocks that have a text field making them taller
   
   var nextBlock: Block? //the block to be executed after this one
   var previousBlock: Block? //block before this one on chain
   var inputField: UITextField? //Only on certain blocks
   
   // Fields for
   var firstNumber = UIButton()
   var operatorLabel: UILabel?
   var secondNumber = UIButton()
   var operatorLabel2: UILabel?
   var thirdNumber: UIButton?
   var equalsLabel: UILabel?
   var answer = UIButton()
   
   //Only on level 2 (and 3?) color block
   var colorPickerButton: UIButton?
   var colorBulbImage: UIImageView?
   
   //Only for repeat blocks
   var blockChainToRepeat: Block?
   var currentWidth: CGFloat //for stretching
   let originalWidth: CGFloat
   
   var selectedButton: UIButton? = nil    // Button for which user is currently entering text
   
   init(withTypeFromString t: String, withView i: UIImageView) {
      
      
      
      type = BlockType.getType(fromString: t)
      imageView = i
      imageView.frame = CGRect(x: imageView.frame.origin.x,y: imageView.frame.origin.y, width: self.originalBlockWidth, height: self.blockHeight)
      originalWidth = i.frame.width
      currentWidth = i.frame.width
      
      //Set the block's offsets so that other block link up properly
      switch type {
      case .controlStart:
         offsetToNext = 0.4*blockHeight
         offsetToPrevious = 0.0 //Should never be a previous block for the start block
         offsetX = 0.0
      case .controlRepeat:
         offsetToNext = 73.0
         offsetToPrevious = 73.0
         offsetX = -2.0
      default:
         offsetToNext = 0.4*blockHeight
         offsetToPrevious = 0.4*blockHeight
         offsetX = 0.0
      }
      
      //Set the group for the block
      switch type {
      case .controlStart, .controlRepeat, .controlWait:
         group = .control
      case .additionLevel3, .subtractionLevel3, .doubleAdditionLevel3,  .moveForwardL2,  .moveBackwardL2,
           .turnRightL2, .turnLeftL2, .moveStopL2:
         group = .motion
      }
      super.init()
      
      //Setup the input field for blocks that need it
      switch type {
      case .additionLevel3:
         let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
         stackView.axis = .vertical
         stackView.distribution = .fill
         stackView.alignment = .fill
         stackView.spacing = 0
         
         let heightOfRectangle = 0.804*blockHeight    // The height minus the bump to fit the next rectangle
         let heightButton = 2*heightOfRectangle/3
         let widthButton = originalWidth/5
         var origin = CGPoint(x: originalWidth/4, y: heightOfRectangle/6)
         let size = CGSize(width: widthButton, height: heightButton)
         firstNumber = UIButton(frame: CGRect(origin: origin, size: size))
//         firstNumber.translatesAutoresizingMaskIntoConstraints = false
//         firstNumber.widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
//         firstNumber.heightAnchor.constraint(greaterThanOrEqualToConstant: 35).isActive = true
         //firstNumber.widthAnchor.constraint(greaterThanOrEqualToConstant: widthButton).isActive = true
         firstNumber.titleLabel?.font = firstNumber.titleLabel?.font.withSize(24)
         var border = CAShapeLayer()
         border.frame = firstNumber.bounds
         border.fillColor = nil
         border.strokeColor = UIColor.gray.cgColor
         border.lineWidth = 2.5
         border.path = UIBezierPath(roundedRect: firstNumber.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 6, height: 6)).cgPath
         firstNumber.layer.addSublayer(border)
         firstNumber.setTitleColor(UIColor.blue, for: .normal)
         firstNumber.addTarget(self, action: #selector(buttonPressed(_ :)), for: .touchUpInside)
         
         origin.x += widthButton
         operatorLabel = UILabel(frame: CGRect(origin: origin, size: size))
         operatorLabel?.textColor = UIColor.black
         operatorLabel?.textAlignment = .center
         operatorLabel?.text = "+"
         
         origin.x += widthButton
         secondNumber = UIButton(frame: CGRect(origin: origin, size: size))
         secondNumber.titleLabel?.font = secondNumber.titleLabel?.font.withSize(24)
         border = CAShapeLayer()
         border.frame = secondNumber.bounds
         border.fillColor = nil
         border.strokeColor = UIColor.gray.cgColor
         border.lineWidth = 2.5
         border.path = UIBezierPath(roundedRect: secondNumber.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 6, height: 6)).cgPath
         secondNumber.layer.addSublayer(border)
         secondNumber.setTitleColor(UIColor.blue, for: .normal)
         secondNumber.addTarget(self, action: #selector(buttonPressed(_ :)), for: .touchUpInside)
         
         origin.x += widthButton
         equalsLabel = UILabel(frame: CGRect(origin: origin, size: size))
         equalsLabel?.textColor = UIColor.black
         equalsLabel?.textAlignment = .center
         equalsLabel?.text = "="
         
         origin.x += widthButton
         answer = UIButton(frame: CGRect(origin: origin, size: size))
         answer.titleLabel?.font = answer.titleLabel?.font.withSize(24)
         border = CAShapeLayer()
         border.frame = answer.bounds
         border.fillColor = nil
         border.strokeColor = UIColor.gray.cgColor
         border.lineWidth = 2.5
         border.path = UIBezierPath(roundedRect: answer.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 6, height: 6)).cgPath
         answer.layer.addSublayer(border)
         answer.setTitleColor(UIColor.blue, for: .normal)
         answer.addTarget(self, action: #selector(buttonPressed(_ :)), for: .touchUpInside)
         
         imageView.addSubview(firstNumber)
         imageView.addSubview(operatorLabel!)
         imageView.addSubview(secondNumber)
         imageView.addSubview(equalsLabel!)
         imageView.addSubview(answer)
         
         origin.x += widthButton
         if origin.x > originalWidth {
            let newFrame = CGRect(x: imageView.frame.minX, y: imageView.frame.minY, width: origin.x + 10, height: blockHeight + 5)
            imageView.frame = newFrame
         }
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
      
      
   }
   
   @objc func buttonPressed(_ sender: UIButton) {
      selectedButton = sender
      
      // Need a view controller to present the pop-up keypad
      let rootViewController = UIApplication.shared.keyWindow?.rootViewController
      
      // Configure the presentation controller
      let storyboard = UIStoryboard(name: "KeyPadStoryboard", bundle: nil)
      let popoverContentController = storyboard.instantiateViewController(withIdentifier: "KeyPadViewController") as? KeyPadViewController
      popoverContentController?.modalPresentationStyle = .popover
      popoverContentController?.preferredContentSize = CGSize(width: 300, height: 400)
      
      // Position the keypad popup
      let buttonFrame = sender.frame
      if let popoverPresentationController = popoverContentController?.popoverPresentationController {
         popoverPresentationController.permittedArrowDirections = [.left, .right]
         popoverPresentationController.sourceView = imageView
         popoverPresentationController.sourceRect = buttonFrame
         popoverContentController?.keyPadDelegate = self
         if let popoverController = popoverContentController {
            rootViewController?.present(popoverController, animated: true, completion: nil)
         }
      }
   }
   
   //MARK: Other
   
   func getPositionForGhost(whenConnectingTo block: Block ) -> CGPoint {
      let X = block.imageView.frame.origin.x
      let Y = block.imageView.center.y + block.offsetToNext + self.offsetToPrevious
      
      return CGPoint(x: X, y: Y)
   }
   
   func goToPosition(whenConnectingTo block: Block) {
      let X = block.imageView.frame.origin.x
      let Y = block.imageView.center.y + block.offsetToNext + self.offsetToPrevious
      
      self.imageView.frame.origin.x = X
      self.imageView.center.y = Y
   }
   
   
   
   func centerPosition(whenInsertingInto block: Block ) -> CGPoint {
      let X = block.imageView.frame.origin.x + 34.0 + self.offsetToPrevious
      let Y = block.imageView.center.y - block.offsetX + self.offsetX
      
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
      if let nextBlock = nextBlock {
         nextBlock.goToPosition(whenConnectingTo: self)
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
   
   //Motion Level 2
   case moveBackwardL2
   case moveForwardL2
   case moveStopL2
   case turnLeftL2
   case turnRightL2
   //Motion Level 3 - still waiting on graphics
   
   case additionLevel3
   case subtractionLevel3
   case doubleAdditionLevel3
   
   
   
   static func getType(fromString string: String) -> BlockType{
      switch string {
      //Control (Level 3 only)
      case "control-start":
         return .controlStart
      case "repeat-x-times":
         return .controlRepeat
      case "wait":
         return .controlWait
         
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
      
      
      case "additionLevel3":
         return .additionLevel3
      case "subtractionLevel3":
         return .subtractionLevel3
      case "doubleAdditionLevel3":
         return .doubleAdditionLevel3
         
      default:
         fatalError("Unknown block type \(string)!")
      }
   }
}
