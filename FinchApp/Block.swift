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
   
   var offsetToNext: CGFloat { //The distance along the y axis to place the next block.
      return 0.4*blockHeight
   }
   var offsetToPrevious: CGFloat {//The distance along the y axis to place the previous block
      if type == .startBlock {
         return 0
      }
      return 0.4*blockHeight
   }
   
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
   var openParentheses = UILabel()
   var closeParentheses = UILabel()
   var nestingOffsetX: CGFloat = 10
   var parent: Block?
   var nestedChild1: Block?
   var nestedChild2: Block?

   var selectedButton: UIButton? = nil    // Button for which user is currently entering text
   
   init(withTypeFromString t: String, withView i: UIImageView) {
      
      type = BlockType.getType(fromString: t)
      imageView = i
      
      //Set the block's offsets so that other block link up properly
      if (type == .additionLevel5) {
         isNestable = true
      } else {
         isNestable = false
         imageView.frame = CGRect(x: imageView.frame.origin.x,y: imageView.frame.origin.y, width: self.originalBlockWidth, height: self.blockHeight)
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
         layoutNestedBlock()
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
            if isNestable {
               layoutNestedBlocksOfTree(containing: self)
            } else {
               layoutBlock(buttonModified: button)
            }
         }
      }
   }
   
   /* This function configures a label in the block. Labels are used for math operators and = */
   func setupLabel(text: String, origin: CGPoint) -> UILabel {
      let label = UILabel(frame: CGRect(origin: origin, size: labelSize))
      label.font = UIFont(name: label.font.fontName, size: 36)
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
      let newFrame = CGRect(x: imageView.frame.minX, y: imageView.frame.minY, width: origin.x + 10, height: blockHeight + 5)
      imageView.frame = newFrame
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
      
      // Now I want to redraw all nested blocks in this tree
      layoutNestedBlocksOfTree(containing: self)
   }
   
   // This block finds the top of a nested tree containing a block and then lays our the entire tree
   func layoutNestedBlocksOfTree(containing block: Block) {
      var outermostBlock = block
      while let parentExists = outermostBlock.parent {
         outermostBlock = parentExists
      }
      outermostBlock.layoutNestedBlock()
   }
   
   func layoutNestedBlock() {
      
      var origin = CGPoint(x: nestingOffsetX, y: heightOfRectangle/6)
      
      // Add opening parentheses
      openParentheses.removeFromSuperview()
      openParentheses = setupLabel(text: "(", origin: origin)
      imageView.addSubview(openParentheses)
      origin.x += openParentheses.frame.width
      
      // We don't want to remove a button if we are currently changing the number in it
      if (selectedButton != nil) && (firstNumber == selectedButton) {
         origin.x += firstNumber.frame.width
      } else {  // Otherwise we want to redraw
         firstNumber.removeFromSuperview()
         if nestedChild1 != nil {
            nestedChild1?.imageView.frame.origin.x = imageView.frame.origin.x + origin.x
            nestedChild1?.imageView.frame.origin.y = imageView.frame.origin.y
            nestedChild1?.bringToFront()
            nestedChild1?.layoutNestedBlock()
            origin.x += nestedChild1?.imageView.frame.width ?? 0
         } else {
            firstNumber = setupButton(text: firstNumber.title(for: .normal) ?? "", origin: origin)
            imageView.addSubview(firstNumber)
            origin.x += firstNumber.frame.width
         }
      }
      operatorLabel.removeFromSuperview()
      operatorLabel = setupLabel(text: mathOperator, origin: origin)
      imageView.addSubview(operatorLabel)
      origin.x += operatorLabel.frame.width
      
      // We don't want to remove a button if we are currently changing the number in it
      if (selectedButton != nil) && (secondNumber == selectedButton) {
         origin.x += secondNumber.frame.width
      } else {  // Otherwise we want to redraw
         secondNumber.removeFromSuperview()
         if nestedChild2 != nil {
            // When child 1 has moved, we need to adjust the position of child 2
            nestedChild2?.imageView.frame.origin.x = imageView.frame.origin.x + origin.x
            nestedChild2?.imageView.frame.origin.y = imageView.frame.origin.y
            nestedChild2?.bringToFront()
            nestedChild2?.layoutNestedBlock()
            origin.x += nestedChild2?.imageView.frame.width ?? 0
         } else {
            secondNumber = setupButton(text: secondNumber.title(for: .normal) ?? "", origin: origin)
            imageView.addSubview(secondNumber)
            origin.x += secondNumber.frame.width
         }
      }
      
      // Add closing parentheses
      closeParentheses.removeFromSuperview()
      closeParentheses = setupLabel(text: ")", origin: origin)
      imageView.addSubview(closeParentheses)
      origin.x += closeParentheses.frame.width
      
      // Resize the frame of the block itself
      let newFrame = CGRect(x: imageView.frame.minX, y: imageView.frame.minY, width: origin.x + nestingOffsetX, height: imageView.frame.height)
      imageView.frame = newFrame
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
      if !isNestable {        // This function shouldn't be called for a nestable block
         if let nextBlock = nextBlock {
            nextBlock.goToPosition(whenConnectingTo: self)
            nextBlock.bringToFront()
            nextBlock.positionChainImages()
         }
      }
   }
   
   //Bring the image views to the front so that the last in the chain is on top
   func bringToFront() {
      imageView.superview?.bringSubview(toFront: imageView)
      if !isNestable {
         nextBlock?.bringToFront()
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
         
         // Redraw the parent tree
         if let parentExists = parent {
            layoutNestedBlocksOfTree(containing: parentExists)
         }
         parent = nil
      } else {
         previousBlock?.nextBlock = nil
      }
      previousBlock = nil
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
