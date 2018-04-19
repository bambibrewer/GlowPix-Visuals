//
//  BlockExecution.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 4/19/18.
//  Copyright © 2018 none. All rights reserved.
//

import Foundation

class BlockExecution: Operation {
    
    let startingBlock: Block
    let finch: FinchPeripheral
    
    init(of block: Block, on finch: FinchPeripheral) {
        self.startingBlock = block
        self.finch = finch
        super.init()
    }
    
    override func main() {
        execute(startingWith: startingBlock)
    }
    
    func execute (startingWith block: Block) {
        
        if isCancelled {
            print ("is cancelled.")
            return
        }
        
        var value = ""
        DispatchQueue.main.sync {
            value = block.inputField?.text ?? "?"
            
            block.imageView.alpha = 0.5
            
            //TODO: Maybe use the shadow to highlight each block?
            //imageView.layer.shadowColor = UIColor.yellow.cgColor
            //imageView.layer.shadowOpacity = 1
            //imageView.layer.shadowOffset = CGSize.zero
            //imageView.layer.shadowRadius = 5
        }
        
        switch block.group {
        case .control:
            switch block.type {
            case .controlStart: print("execute control start")
            case .controlRepeat:
                print("execute control repeat \(value) times")
                if let x = Int(value), let chainToRepeat = block.blockChainToRepeat {
                    for _ in 0 ..< x {
                        if isCancelled {
                            DispatchQueue.main.sync { block.imageView.alpha = 1.0 }
                            return
                        }
                        execute(startingWith: chainToRepeat)
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
            switch block.type {
            case .moveForwardL1:
                print("execute level 1 move forward")
                usleep(block.executionDuration)
                print("stop level 1 move forward")
            case .moveForwardL2:
                print("execute level 2 move forward by \(value)")
                usleep(block.executionDuration)
                print("stop level 2 move forward")
            case .moveBackwardL1:
                print("execute level 1 move backward")
                usleep(block.executionDuration)
                print("stop level 1 move backward")
            case .moveBackwardL2:
                print("execute level 2 move backward by \(value)")
                usleep(block.executionDuration)
                print("stop level 2 move backward")
            case .turnLeftL1:
                print("execute level 1 turn left")
                usleep(block.executionDuration)
                print("stop level 1 turn left")
            case .turnLeftL2:
                print("execute level 2 turn left by \(value)")
                usleep(block.executionDuration)
                print("stop level 2 turn left")
            case .turnRightL1:
                print("execute level 1 turn right")
                usleep(block.executionDuration)
                print("stop level 1 turn right")
            case .turnRightL2:
                print("execute level 2 turn right by \(value)")
                usleep(block.executionDuration)
                print("stop level 2 turn right")
            case .moveStop:
                print("execute move stop")
                usleep(block.executionDuration)
            default: print("Trying to execute a block in group motion that is not listed.")
            }
            let success = finch.setServo(port: 1, angle: 90)
            if !success {
                print("Failed to execute motion.")
            }
        case .sound:
            switch block.type {
            case .soundL1:
                print("execute level 1 sound")
                usleep(block.executionDuration)
                print("stop level 1 sound")
            case .soundL23:
                print("execute level 2 and 3 sound: \(value)")
                usleep(block.executionDuration)
                print("stop level 2 and 3 sound")
            default: print("Trying to execute a block in group sound that is not listed.")
            }
        case .color:
            var intensities: BBTTriLED?
            switch block.type {
            case .colorRed: intensities = BBTTriLED.init(255, 0, 0)
            case .colorYellow: intensities = BBTTriLED.init(255, 255, 0)
            case .colorGreen: intensities = BBTTriLED.init(0, 255, 0)
            case .colorCyan: intensities = BBTTriLED.init(0, 255, 255)
            case .colorBlue: intensities = BBTTriLED.init(0, 0, 255)
            case .colorMagenta: intensities = BBTTriLED.init(255, 0, 255)
            case .colorOff: intensities = BBTTriLED.init(0, 0, 0)
            case .colorWheel:
                DispatchQueue.main.sync { intensities = block.getIntenities() }
            default: print("Trying to execute a block in group color that is not listed.")
            }
            if let intensities = intensities {
                let success = finch.setTriLED(port: 1, intensities: intensities)
                if !success { print("Failed to set color.") }
                usleep(block.executionDuration)
            } else {
                print ("Somehow, the intensity was never set before trying to set led.")
            }
        }
        
        DispatchQueue.main.sync { block.imageView.alpha = 1.0 }
        
        if let nextBlock = block.nextBlock {
            execute(startingWith: nextBlock)
        }
    }
    
}
