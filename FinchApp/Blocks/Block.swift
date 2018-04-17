//
//  Block.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import Foundation
import UIKit

class Block: NSObject, UIPopoverPresentationControllerDelegate, ColorPickerViewControllerDelegate {
    
    let executionDuration: UInt32 //The amount of time the block will sleep during execution
    
    let type: BlockType
    let group: BlockGroup
    let imageView: UIImageView
    let offsetToNext: CGFloat //The distance along the x axis to place the next block.
    let offsetToPrevious: CGFloat //The distance along the x axis to place the previous block
    let offsetY: CGFloat //The offset on the y axis for blocks that have a text field making them taller
    
    var nextBlock: Block? //the block to be executed after this one
    var previousBlock: Block? //block before this one on chain
    var inputField: UITextField? //Only on certain blocks
    
    //Only on level 2 (and 3?) color block
    var colorPickerButton: UIButton?
    var colorBulbImage: UIImageView?
    
    //Only for repeat blocks
    var blockChainToRepeat: Block?
    
    init(withTypeFromString t: String, withView i: UIImageView) {
        
        type = BlockType.getType(fromString: t)
        imageView = i
        
        //Set how long the block will be executed for
        switch type{
        case .controlStart, .controlRepeat, .controlWait: executionDuration = 0
        case .moveForwardL1, .moveBackwardL1, .turnLeftL1, .turnRightL1,
             .colorRed, .colorYellow, .colorGreen, .colorCyan, .colorBlue,
             .colorMagenta, .soundL1: executionDuration = 1000000 //one second
        case .moveForwardL2, .moveBackwardL2, .turnLeftL2, .turnRightL2,
             .moveStop, .colorOff, .colorWheel, .soundL23: executionDuration = 500000
        }
        
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
        case .moveForwardL2, .moveBackwardL2, .turnRightL2, .turnLeftL2, .soundL23, .controlWait:
            offsetToNext = 32.0
            offsetToPrevious = 32.0
            offsetY = 4.0
        default:
            offsetToNext = 32.0
            offsetToPrevious = 32.0
            offsetY = 0.0
        }
        
        //Set the group for the block
        switch type {
        case .controlStart, .controlRepeat, .controlWait:
            group = .control
        case .colorRed, .colorYellow, .colorGreen, .colorCyan, .colorBlue, .colorMagenta, .colorOff, .colorWheel:
            group = .color
        case .soundL1, .soundL23:
            group = .sound
        case .moveForwardL1, .moveForwardL2, .moveBackwardL1, .moveBackwardL2, .turnRightL1, .turnRightL2, .turnLeftL1, .turnLeftL2, .moveStop:
            group = .motion
        }
        
        //Setup the input field for blocks that need it
        switch type {
        case .controlRepeat, .controlWait, .moveForwardL2, .moveBackwardL2, .turnLeftL2, .turnRightL2, .soundL23:
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
        
        //For level 2 color block, need a button to pick the color
        if type == .colorWheel {
            let buttonOrigin = CGPoint(x: 28.0, y: 57.0)
            let buttonSize = CGSize(width: 20.0, height: 20.0)
            colorPickerButton = UIButton(frame: CGRect(origin: buttonOrigin, size: buttonSize))
            colorPickerButton?.setImage(UIImage.init(named: "Eight-colour-wheel-2D"), for: .normal)
            colorPickerButton?.addTarget(self, action: #selector(pickColor(_:)), for: .touchUpInside)
            colorPickerButton?.addTarget(self, action: #selector(pickColor(_:)), for: .touchUpOutside)
            imageView.addSubview(colorPickerButton!)
            
            let bulbOrigin = CGPoint(x: 20.0, y: 9.0)
            let bulbSize = CGSize(width: 35.0, height: 39.0)
            colorBulbImage = UIImageView(frame: CGRect(origin: bulbOrigin, size: bulbSize))
            let bulb = UIImage(named: "bulb-icon")?.withRenderingMode(.alwaysTemplate)
            colorBulbImage?.image = bulb
            colorBulbImage?.tintColor = .white
            imageView.addSubview(colorBulbImage!)
        }
    }
    
    //MARK: Color picker methods
    
    @objc func pickColor(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let colorPickerVC = storyboard.instantiateViewController(withIdentifier: "colorPicker") as? ColorPickerViewController else {
            fatalError("Could not instantiate color picker view controller.")
        }
        
        colorPickerVC.delegate = self
        colorPickerVC.modalPresentationStyle = .popover
        colorPickerVC.popoverPresentationController?.delegate = self //TODO: need this?
        colorPickerVC.popoverPresentationController?.sourceView = sender
        colorPickerVC.popoverPresentationController?.sourceRect = sender.bounds

        let mainViewController = UIApplication.shared.keyWindow?.rootViewController
        mainViewController?.present(colorPickerVC, animated: true, completion: nil)
    }
    
    func didPickColor(_ color: UIColor) {
        print("did pick color")
        self.colorBulbImage?.tintColor = color
    }
    
    //MARK: Other private methods
    
    private func getIntenities() -> BBTTriLED {
        guard let color = colorBulbImage?.tintColor else {
            fatalError("Could not get color from bulb icon")
        }
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if color.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = UInt8(fRed * 255.0)
            let iGreen = UInt8(fGreen * 255.0)
            let iBlue = UInt8(fBlue * 255.0)
            //let iAlpha = UInt8(fAlpha * 255.0)
            
            return BBTTriLED.init(iRed, iGreen, iBlue)
        } else {
            fatalError("Failed to get the intensities from the bulb icon")
        }
    }
    
    
    
    //MARK: Public methods
    
    func centerPosition(whenConnectingTo block: Block ) -> CGPoint {
        var X = block.imageView.center.x + block.offsetToNext + self.offsetToPrevious
        let Y = block.imageView.center.y - block.offsetY + self.offsetY
        
        if block.shouldAttachAsChainToRepeat(self) {
            X = block.imageView.center.x - 48.0 + self.offsetToPrevious
        }
        
        return CGPoint(x: X, y: Y)
    }
    
    func attachBlock (_ b: Block){
        
        if shouldAttachAsChainToRepeat(b)  {
            blockChainToRepeat = b
        } else {
            nextBlock = b
        }
        b.previousBlock = self
        positionChainImages()
    }
    
    func shouldAttachAsChainToRepeat (_ b: Block) -> Bool {
        //Crude determination of whether this will be a subchain
        return type == .controlRepeat && imageView.frame.origin.x + 50.0 > b.imageView.frame.origin.x
    }
    
    //Put into position all of the images of a chain connecting to this one
    func positionChainImages(){
        if let nextBlock = nextBlock {
            nextBlock.imageView.center = nextBlock.centerPosition(whenConnectingTo: self)
            nextBlock.positionChainImages()
        }
        if let repeater = blockChainToRepeat {
            repeater.imageView.center = repeater.centerPosition(whenConnectingTo: self)
            repeater.positionChainImages()
        }
    }
    
    func detachPreviousBlock(){
        if previousBlock?.blockChainToRepeat == self {
            previousBlock?.blockChainToRepeat = nil
        }else{
            previousBlock?.nextBlock = nil
        }
        previousBlock = nil
    }
    
    //Bring the image views to the front so that the last in the chain is on top
    func bringToFront() {
        imageView.superview?.bringSubview(toFront: imageView)
        blockChainToRepeat?.bringToFront()
        nextBlock?.bringToFront()
    }
    
    //This function cannot be run on the main queue
    func execute (on finch: FinchPeripheral) {
        
        var value = ""
        DispatchQueue.main.sync {
            value = inputField?.text ?? "?"
            
            imageView.alpha = 0.5
            
            //TODO: Maybe use the shadow to highlight each block?
            //imageView.layer.shadowColor = UIColor.yellow.cgColor
            //imageView.layer.shadowOpacity = 1
            //imageView.layer.shadowOffset = CGSize.zero
            //imageView.layer.shadowRadius = 5
        }
        
        switch group {
        case .control:
            switch type {
            case .controlStart: print("execute control start")
            case .controlRepeat:
                print("execute control repeat \(value) times")
                if let x = Int(value) {
                    for _ in 0 ..< x {
                        blockChainToRepeat?.execute(on: finch)
                    }
                }
            case .controlWait:
                print("execute control wait for \(value)")
                if let waitTime = UInt32(value) {
                    usleep(waitTime * 100000)
                }
            default: print("Trying to execute a block in group control that is not listed.")
            }
        case .motion:
            switch type {
            case .moveForwardL1:
                print("execute level 1 move forward")
                usleep(executionDuration)
                print("stop level 1 move forward")
            case .moveForwardL2:
                print("execute level 2 move forward by \(value)")
                usleep(executionDuration)
                print("stop level 2 move forward")
            case .moveBackwardL1:
                print("execute level 1 move backward")
                usleep(executionDuration)
                print("stop level 1 move backward")
            case .moveBackwardL2:
                print("execute level 2 move backward by \(value)")
                usleep(executionDuration)
                print("stop level 2 move backward")
            case .turnLeftL1:
                print("execute level 1 turn left")
                usleep(executionDuration)
                print("stop level 1 turn left")
            case .turnLeftL2:
                print("execute level 2 turn left by \(value)")
                usleep(executionDuration)
                print("stop level 2 turn left")
            case .turnRightL1:
                print("execute level 1 turn right")
                usleep(executionDuration)
                print("stop level 1 turn right")
            case .turnRightL2:
                print("execute level 2 turn right by \(value)")
                usleep(executionDuration)
                print("stop level 2 turn right")
            case .moveStop:
                print("execute move stop")
                usleep(executionDuration)
            default: print("Trying to execute a block in group motion that is not listed.")
            }
            let success = finch.setServo(port: 1, angle: 90)
            if !success {
                print("Failed to execute motion.")
            }
        case .sound:
            switch type {
            case .soundL1:
                print("execute level 1 sound")
                usleep(executionDuration)
                print("stop level 1 sound")
            case .soundL23:
                print("execute level 2 and 3 sound: \(value)")
                usleep(executionDuration)
                print("stop level 2 and 3 sound")
            default: print("Trying to execute a block in group sound that is not listed.")
            }
        case .color:
            var intensities: BBTTriLED?
            switch type {
            case .colorRed: intensities = BBTTriLED.init(255, 0, 0)
            case .colorYellow: intensities = BBTTriLED.init(255, 255, 0)
            case .colorGreen: intensities = BBTTriLED.init(0, 255, 0)
            case .colorCyan: intensities = BBTTriLED.init(0, 255, 255)
            case .colorBlue: intensities = BBTTriLED.init(0, 0, 255)
            case .colorMagenta: intensities = BBTTriLED.init(255, 0, 255)
            case .colorOff: intensities = BBTTriLED.init(0, 0, 0)
            case .colorWheel:
                DispatchQueue.main.sync { intensities = getIntenities() }
            default: print("Trying to execute a block in group color that is not listed.")
            }
            if let intensities = intensities {
                let success = finch.setTriLED(port: 1, intensities: intensities)
                if !success { print("Failed to set color.") }
                usleep(executionDuration)
            } else {
                print ("Somehow, the intensity was never set before trying to set led.")
            }
        }
        
        DispatchQueue.main.sync { imageView.alpha = 1.0 }
        
        nextBlock?.execute(on: finch)
    }
    
    
    
}

enum BlockGroup {
    case control
    case motion
    case sound
    case color
}

enum BlockType {
    case controlStart
    case controlRepeat
    case controlWait
    case moveBackwardL1
    case moveForwardL1
    case turnLeftL1
    case turnRightL1
    case moveBackwardL2
    case moveForwardL2
    case moveStop
    //case moveStopFinal //where did I get this idea from?
    case turnLeftL2
    case turnRightL2
    case colorBlue
    case colorCyan
    case colorGreen
    case colorMagenta
    case colorOff
    case colorRed
    case colorYellow
    case colorWheel
    case soundL1
    case soundL23
    //case bulbIcon
    
    static func getType(fromString string: String) -> BlockType{
        switch string {
        case "control-start":
            return .controlStart
        case "repeat-x-times":
            return .controlRepeat
        case "wait":
            return .controlWait
        case "move-forward":
            return .moveForwardL1
        case "move-backward":
            return .moveBackwardL1
        case "turn-left":
            return .turnLeftL1
        case "turn-right":
            return .turnRightL1
        case "move-forward-L2":
            return .moveForwardL2
        case "move-backward-L2":
            return .moveBackwardL2
        case "turn-left-L2":
            return .turnLeftL2
        case "turn-right-L2":
            return .turnRightL2
        case "move-stop":
            return .moveStop
        case "sound-L1":
            return .soundL1
        case "sound-L2":
            return .soundL23
        case "color-red":
            return .colorRed
        case "color-yellow":
            return .colorYellow
        case "color-green":
            return .colorGreen
        case "color-cyan":
            return .colorCyan
        case "color-blue":
            return .colorBlue
        case "color-magenta":
            return .colorMagenta
        case "color-off":
            return .colorOff
        case "blank-color":
            return .colorWheel
        case "color-off-L2":
            return .colorOff
        default:
            fatalError("Unknown block type \(string)!")
        }
    }
}
