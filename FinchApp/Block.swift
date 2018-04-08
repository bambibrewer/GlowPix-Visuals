//
//  Block.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 3/20/18.
//  Copyright © 2018 none. All rights reserved.
//

import Foundation
import UIKit

class Block {
    
    let type: BlockType
    let imageView: UIImageView
    let level: Int
    let offset: CGFloat //The distance along the x axis to place the next block.
    
    var nextBlock: Block? //the block to be executed after this one
    var previousBlock: Block? //block before this one on chain
    
    
    init(withTypeFromString t: String, withView i: UIImageView, forLevel l: Int) {
        type = BlockType.getType(fromString: t)
        imageView = i
        level = l
        
        switch type {
        case .controlStart:
            offset = 56.0
        default:
            offset = 63.0
        }
    }
    
    func attachBlock (_ b: Block){
        nextBlock = b
        b.previousBlock = self
    }
    
    func detachPreviousBlock(){
        previousBlock?.nextBlock = nil
        previousBlock = nil
    }
    
    func execute (on finch: FinchPeripheral) {
        switch type {
        case .colorRed:
            print ("execute color red.")
            let success = finch.setTriLED(port: 1, intensities: BBTTriLED.init(255, 0, 0))
            if !success {
                print("Failed to set red.")
            }
        case .colorBlue:
            print ("execute color blue.")
            let success = finch.setTriLED(port: 1, intensities: BBTTriLED.init(0, 0, 255))
            if !success {
                print("Failed to set blue.")
            }
        case .colorGreen:
            print ("execute color green.")
            let success = finch.setTriLED(port: 1, intensities: BBTTriLED.init(0, 255, 0))
            if !success {
                print("Failed to set green.")
            }
        case .colorOff:
            print ("execute color off.")
            let success = finch.setTriLED(port: 1, intensities: BBTTriLED.init(0, 0, 0))
            if !success {
                print("Failed to turn off led.")
            }
        case .turnLeftL1:
            print("execute turn left.")
            let success = finch.setServo(port: 1, angle: 90)
            if !success {
                print("Failed to set servo left.")
            }
        default: ()
        }
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
    case repeatXTimes
    case wait
    case moveBackwardL1
    case moveForwardL1
    case turnLeftL1
    case turnRightL1
    case moveBackwardL23
    case moveForwardL23
    case moveStop
    case moveStopFinal
    case turnLeftL23
    case turnRightL23
    case colorBlue
    case colorCyan
    case colorGreen
    case colorMagenta
    case colorOff
    case colorRed
    case colorYellow
    case soundL1
    case soundL23
    case bulbIcon
    
    static func getType(fromString string: String) -> BlockType{
        switch string {
        case "control-start":
            return .controlStart
        case "move-forward":
            return .moveForwardL1
        case "move-backward":
            return .moveBackwardL1
        case "turn-left":
            return .turnLeftL1
        case "turn-right":
            return .turnRightL1
        case "sound-L1":
            return .soundL1
        case "color-red":
            return .colorRed
        case "color-green":
            return .colorGreen
        case "color-blue":
            return .colorBlue
        case "color-off":
            return .colorOff
        default:
            fatalError("Unknown block type \(string)!")
        }
    }
}
