//
//  OsuHitObjectType.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

import SpriteKit

// Enum para los tipos de objetos en osu!
enum OsuHitObjectType: Int {
    case circle = 1     // 1 << 0
    case slider = 2     // 1 << 1
    case spinner = 8    // 1 << 3
    
    static func getType(from value: Int) -> [OsuHitObjectType] {
        var types: [OsuHitObjectType] = []
        
        if (value & OsuHitObjectType.circle.rawValue) != 0 {
            types.append(.circle)
        }
        if (value & OsuHitObjectType.slider.rawValue) != 0 {
            types.append(.slider)
        }
        if (value & OsuHitObjectType.spinner.rawValue) != 0 {
            types.append(.spinner)
        }
        
        return types
    }
}
