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
      if let num = number, let button = selectedButton {
         button.setTitle(" \(num) ", for: .normal)
         if (button.titleLabel?.intrinsicContentSize.width ?? 0 > widthOfButton) || (button.frame.width > widthOfButton) {
            button.sizeToFit()
            addBorder(button: button)
            // If it is a large number, we need to shift everything else to the right
            layoutBlock(blockModified: button)
         }
      }
   }
   
   func setupLabel(text: String, origin: CGPoint) -> UILabel {
      let label = UILabel(frame: CGRect(origin: origin, size: labelSize))
      label.textColor = UIColor.black
      label.textAlignment = .center
      label.text = text
      return label
   }
   
   func setupButton(text: String, origin: CGPoint) -> UIButton {
      let button = UIButton(frame: CGRect(origin: origin, size: buttonSize))
      button.titleLabel?.font = button.titleLabel?.font.withSize(24)
      button.setTitleColor(UIColor.blue, for: .normal)
      button.addTarget(self, action: #selector(buttonPressed(_ :)), for: .touchUpInside)
      button.setTitle(text, for: .normal)
      if (button.titleLabel?.intrinsicContentSize.width ?? 0 > widthOfButton) || (button.frame.width > widthOfButton){
         button.sizeToFit()
      }
      addBorder(button: button)
      return button
   }
   
   func layoutBlock(blockModified: UIButton)
   {
      var origin = blockModified.frame.origin
//      let subViews = [operatorLabel, secondNumber, equalsLabel, answer]
//      let subViewsToChange = subViews.filter{($0.frame.origin.x > origin.x)}
//      print(subViewsToChange.count)
      
      if (blockModified == firstNumber) {
         operatorLabel.removeFromSuperview()
         origin.x += firstNumber.frame.width
         operatorLabel = setupLabel(text: mathOperator, origin: origin)
         imageView.addSubview(operatorLabel)
         
         secondNumber.removeFromSuperview()
         origin.x += operatorLabel.frame.width
         secondNumber = setupButton(text: secondNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(secondNumber)
      }
      
      if (blockModified == firstNumber) || (blockModified == secondNumber) {
         equalsLabel.removeFromSuperview()
         origin.x += secondNumber.frame.width
         equalsLabel = setupLabel(text: "=", origin: origin)
         imageView.addSubview(equalsLabel)
         
         answer.removeFromSuperview()
         origin.x += equalsLabel.frame.width
         answer = setupButton(text: answer.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(answer)
      }
      
      // Resize the frame of the block itself
      origin.x += answer.frame.width
      if origin.x > originalWidth {
         let newFrame = CGRect(x: imageView.frame.minX, y: imageView.frame.minY, width: origin.x + 10, height: blockHeight + 5)
         imageView.frame = newFrame
      }
      
   }
   
   let type: BlockType
   let imageView: UIImageView
   
   let blockHeight:CGFloat = 80
   let originalBlockWidth: CGFloat = 261.1
   var heightOfRectangle: CGFloat {
      return 0.804*blockHeight
   }
   var heightOfButton: CGFloat {
      return 2*heightOfRectangle/3
   }
   
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
      
      super.init()
      
      //Setup the input field for blocks that need it
      switch type {
      case .additionLevel3:
         mathOperator = "+"
         let origin = CGPoint(x: originalBlockWidth/4, y: heightOfRectangle/6)
         firstNumber = setupButton(text: firstNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(firstNumber)
         layoutBlock(blockModified: firstNumber)
      case .subtractionLevel3:
         mathOperator = "−"
         let origin = CGPoint(x: originalBlockWidth/4, y: heightOfRectangle/6)
         firstNumber = setupButton(text: firstNumber.title(for: .normal) ?? "", origin: origin)
         imageView.addSubview(firstNumber)
         layoutBlock(blockModified: firstNumber)
      case .doubleAdditionLevel3:
         mathOperator = "+"
         thirdNumber = UIButton()
         operatorLabel2 = UILabel()
         layoutBlock(blockModified: firstNumber)
      case .controlRepeat:
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
            previousBlock.resizeFutureNestedBlocks()
            previousBlock.positionChainImages()
         }
         previousBlock.resizeRepeatBlocks()
      }
   }
   
   func resizeFutureNestedBlocks() {
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
         previousBlock?.resizeFutureNestedBlocks()
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


enum BlockType {
   //Control (Level 3 only except start)
   case controlStart
   case controlRepeat
   
   
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
