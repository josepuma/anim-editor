//
//  Helpers.swift
//  anim-editor
//
//  Created by José Puma on 01-11-24.
//

import SpriteKit

class Helpers {
    
    static func randomIntBetween(_ min: Int, _ max: Int) -> Int {
        return Int.random(in: min...max)
    }
    
    static func randomFloatBetween(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
        return CGFloat.random(in: min...max)
    }
    
}
