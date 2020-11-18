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
   
   let type: BlockType
   let imageView: UIImageView
   let isNestable: Bool
   
   /* All of these variable control the size of the blocks, and the size of the number buttons and labels within them. */
   let blockHeight:CGFloat = 80
   var heightOfRectangle: CGFloat {
      return 0.804*blockHeight
   }
   var heightOfButton: CGFloat {
      return 2*heightOfRectangle/3
   }
   
   let originalBlockWidth: CGFloat = 261.1
   var widthOfButton: CGFloat {
      return originalBlockWidth/4
   }
   
   var buttonSize: CGSize {
      return CGSize(width: widthOfButton, height: heightOfButton)
   }
   
   var labelWidth: CGFloat {
      return originalBlockWidth/8
   }
   var labelSize: CGSize {
      return CGSize(width: labelWidth, height: heightOfButton)
   }
   
   
   var offsetToNext: CGFloat //The distance along the y axis to place the next block.
   var offsetToPrevious: CGFloat //The distance along the y axis to place the previous block
   let offsetX: CGFloat //The offset on the x axis for blocks that have a text field making them taller
   
   var nextBlock: Block? //the block to be executed after this one
   var previousBlock: Block? //block before this one on chain
   var inputField: UITextField? //Only on certain blocks
   
   var mathOperator = "+"
   
   var firstNumber = UIButton()
   var operatorLabel = UILabel()
   var secondNumber = UIButton()
   var operatorLabel2: UILabel?
   var thirdNumber: UIButton?
   var equalsLabel = UILabel()
   var answer = UIButton()
   
   // Only for blocks that nest
   var nestingOffsetX: CGFloat = 30
   var parent: Block?
   var nestedChild1: Block?
   var nestedChild2: Block?
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
      case .startBlock:
         offsetToNext = 0.4*blockHeight
         offsetToPrevious = 0.0 //Should never be a previous block for the start block
         offsetX = 0.0
         isNestable = false
      case .additionLevel5:
         offsetToNext = 0.4*blockHeight//73.0
         offsetToPrevious = 0.4*blockHeight//73.0
         offsetX = 0.0//-2.0
         isNestable = true
      default:
         offsetToNext = 0.4*blockHeight
         offsetToPrevious = 0.4*blockHeight
         offsetX = 0.0
         isNestable = false
      }
      
      super.init()
      
      //Setup the input field for blocks that need it
      switch type {
      case .additionLevel3:
         mathOperator = "+"
         let origin = CGPoint(x: originalBlockWidth/4, y: heightOfRectangle/6)
         firstNumber = setupButton(text: firstNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(firstNumber)
         layoutBlock(buttonModified: firstNumber)
      case .subtractionLevel3:
         mathOperator = "−"
         let origin = CGPoint(x: originalBlockWidth/4, y: heightOfRectangle/6)
         firstNumber = setupButton(text: firstNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(firstNumber)
         layoutBlock(buttonModified: firstNumber)
      case .doubleAdditionLevel3:
         mathOperator = "+"
         thirdNumber = UIButton()
         operatorLabel2 = UILabel()
         let origin = CGPoint(x: originalBlockWidth/4, y: heightOfRectangle/6)
         firstNumber = setupButton(text: firstNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(firstNumber)
         layoutBlock(buttonModified: firstNumber)
      case .additionLevel5:
         mathOperator = "+"
         var origin = CGPoint(x: originalBlockWidth/4, y: heightOfRectangle/6)
         firstNumber = setupButton(text: firstNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(firstNumber)
         
         origin.x += firstNumber.frame.width
         operatorLabel = setupLabel(text: mathOperator, origin: origin)
         imageView.addSubview(operatorLabel)
         
         origin.x += operatorLabel.frame.width
         secondNumber = setupButton(text: secondNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(secondNumber)
      default: ()
      }
      
      
   }
   
   /* This is the function that is called when a user taps a number on the pop-up number pad. */
   func numberChanged(number: Int?) {
      if let num = number, let button = selectedButton {
         button.setTitle(" \(num) ", for: .normal)
         if (button.titleLabel?.intrinsicContentSize.width ?? 0 > widthOfButton) {
            button.sizeToFit()
            addBorder(button: button)
            // If we changed the width of the button, we need to shift everything else to the right
            layoutBlock(buttonModified: button)
         }
      }
   }
   
   /* This function configures a label in the block. Labels are used for math operators and = */
   func setupLabel(text: String, origin: CGPoint) -> UILabel {
      let label = UILabel(frame: CGRect(origin: origin, size: labelSize))
      label.textColor = UIColor.black
      label.textAlignment = .center
      label.text = text
      return label
   }
   
   /* This function configures a button in the block. The buttons are where the user enters numbers.*/
   func setupButton(text: String, origin: CGPoint) -> UIButton {
      let button = UIButton(frame: CGRect(origin: origin, size: buttonSize))
      button.titleLabel?.font = button.titleLabel?.font.withSize(24)
      button.setTitleColor(UIColor.blue, for: .normal)
      button.addTarget(self, action: #selector(buttonPressed(_ :)), for: .touchUpInside)
      button.setTitle(text, for: .normal)
      if (button.titleLabel?.intrinsicContentSize.width ?? 0 > widthOfButton) {
         button.sizeToFit()
      }
      addBorder(button: button)
      return button
   }
   
   func layoutBlock(buttonModified: UIButton)
   {
      var origin = buttonModified.frame.origin
      let isThirdNumber = (thirdNumber != nil) && (operatorLabel2 != nil)
      
      // The first operator and the second number only move if the first number is changing
      if (buttonModified == firstNumber) {
         operatorLabel.removeFromSuperview()
         origin.x += firstNumber.frame.width
         operatorLabel = setupLabel(text: mathOperator, origin: origin)
         imageView.addSubview(operatorLabel)
         
         secondNumber.removeFromSuperview()
         origin.x += operatorLabel.frame.width
         secondNumber = setupButton(text: secondNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(secondNumber)
      }
      
      // If this is the ++ block and the 1st or 2nd number has changed, the second operator and third number need to move
      if ((buttonModified == firstNumber) || (buttonModified == secondNumber)) && isThirdNumber {
         operatorLabel2?.removeFromSuperview()
         origin.x += secondNumber.frame.width
         operatorLabel2 = setupLabel(text: mathOperator, origin: origin)
         imageView.addSubview(operatorLabel2!)
         
         thirdNumber?.removeFromSuperview()
         origin.x += operatorLabel2!.frame.width
         thirdNumber = setupButton(text: thirdNumber?.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(thirdNumber!)
         
      }
      
      // If anything except the answer has been changed, then we need to move the equals sign and the answer
      if (selectedButton != answer) {
         equalsLabel.removeFromSuperview()
         origin.x += isThirdNumber ? thirdNumber!.frame.width : secondNumber.frame.width
         equalsLabel = setupLabel(text: "=", origin: origin)
         imageView.addSubview(equalsLabel)
         
         answer.removeFromSuperview()
         origin.x += equalsLabel.frame.width
         answer = setupButton(text: answer.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(answer)
      }
      
      // No matther what block was selected, resize the frame of the block itself
      origin.x += answer.frame.width
      if origin.x > originalWidth {
         let newFrame = CGRect(x: imageView.frame.minX, y: imageView.frame.minY, width: origin.x + 10, height: blockHeight + 5)
         imageView.frame = newFrame
      }      
   }
   
   /* This function removes any previous borders */
   fileprivate func removePreviousBorders(_ view: UIView) {
      if let sublayers = view.layer.sublayers {
         for sublayer in sublayers {
            if sublayer is CAShapeLayer {
               sublayer.removeFromSuperlayer()
            }
         }
      }
   }
   
   func addBorder(button: UIButton) {
      removePreviousBorders(button)
      let border = CAShapeLayer()
      border.frame = button.bounds
      border.fillColor = nil
      border.strokeColor = UIColor.gray.cgColor
      border.lineWidth = 2.5
      border.path = UIBezierPath(roundedRect: button.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 6, height: 6)).cgPath
      button.layer.addSublayer(border)
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
   
   
   //Attach a block chain below this one
   func attachBlock (_ b: Block){
      if let nextBlock = nextBlock {
         b.attachToChain(nextBlock)
      }
      nextBlock = b
      b.previousBlock = self
      positionChainImages()
   }
   
   // Insert a block into this one (only for nesting blocks)
   func insertBlock (blockToInsert: Block, intoButton: UIButton){
      if !isNestable {
         fatalError("insertBlock should only be called for blocks that can nest")
      }
      
      if intoButton == firstNumber {
         nestedChild1 = blockToInsert
      } else {
         nestedChild2 = blockToInsert
      }
      
      // Now I want to redraw, but I want to call the drawing function only on the outermost block
      var outermostBlock = self
      while let parentExists = outermostBlock.parent {
         outermostBlock = parentExists
      }
      outermostBlock.drawNestedBlock()
   }
   
   func drawNestedBlock() {
      // Need to clean up what is happening here with origin!!
      
      var origin = CGPoint(x: 0, y: heightOfRectangle/6)
      
      if nestedChild1 != nil {
         nestedChild1?.imageView.frame.origin.x = imageView.frame.origin.x + nestingOffsetX
         nestedChild1?.imageView.frame.origin.y = imageView.frame.origin.y
         nestedChild1?.drawNestedBlock()
         
         origin = CGPoint(x: nestingOffsetX, y: heightOfRectangle/6)
         origin.x += nestedChild1?.imageView.frame.width ?? 0
      } else {
         origin = firstNumber.frame.origin
         origin.x += firstNumber.frame.width
      }
      
      operatorLabel.removeFromSuperview()
      operatorLabel = setupLabel(text: mathOperator, origin: origin)
      imageView.addSubview(operatorLabel)
      origin.x += operatorLabel.frame.width
      
      if nestedChild2 != nil {
         // When child 1 has moved, we need to adjust the position of child 2
         nestedChild2?.imageView.frame.origin.x = imageView.frame.origin.x + origin.x
         nestedChild2?.imageView.frame.origin.y = imageView.frame.origin.y
         nestedChild2?.drawNestedBlock()
         origin.x += nestedChild2?.imageView.frame.width ?? 0
      } else {
         secondNumber.removeFromSuperview()
         secondNumber = setupButton(text: secondNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(secondNumber)
         origin.x += secondNumber.frame.width
      }
      
      // Resize the frame of the block itself
      //if origin.x > originalWidth {
         let newFrame = CGRect(x: imageView.frame.minX, y: imageView.frame.minY, width: origin.x + 10, height: imageView.frame.height)
         imageView.frame = newFrame
      //}
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
   
   func goToPosition(whenConnectingTo block: Block) {
      let X = block.imageView.frame.origin.x
      let Y = block.imageView.center.y + block.offsetToNext + self.offsetToPrevious
      
      self.imageView.frame.origin.x = X
      self.imageView.center.y = Y
   }
   
   // Position the vertical stack of blocks
   func positionChainImages(){
      if let nextBlock = nextBlock {
         nextBlock.goToPosition(whenConnectingTo: self)
         nextBlock.positionChainImages()
      }
   }
   
   // Detach a block from the previous block in a vertical chain or from its parents, if it is nestable
   func detachBlock(){
      if isNestable {
         if self == parent?.nestedChild1 {
            parent?.nestedChild1 = nil
         } else {
            parent?.nestedChild2 = nil
         }
         parent?.drawNestedBlock()
         parent = nil
      } else {
         previousBlock?.nextBlock = nil
      }
      previousBlock = nil
   }
   
   //Bring the image views to the front so that the last in the chain is on top
   func bringToFront() {
//      imageView.superview?.bringSubview(toFront: imageView)
//      blockChainToRepeat?.bringToFront()
//      nextBlock?.bringToFront()
   }
   
}


enum BlockType {
   //Control (Level 3 only except start)
   case startBlock
   case additionLevel5
   
   
   case additionLevel3
   case subtractionLevel3
   case doubleAdditionLevel3
   
   
   
   static func getType(fromString string: String) -> BlockType{
      switch string {
      //Control (Level 3 only)
      case "start":
         return .startBlock
      case "additionLevel5":
         return .additionLevel5
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
