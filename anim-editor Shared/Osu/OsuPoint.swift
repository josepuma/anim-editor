//
//  OsuPoint.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

import SpriteKit

struct OsuPoint {
    var x: CGFloat
    var y: CGFloat
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    init(fromString string: String) {
        let components = string.split(separator: ":").map { String($0) }
        self.x = CGFloat(Double(components[0]) ?? 0)
        self.y = CGFloat(Double(components[1]) ?? 0)
    }
    
    // Convierte coordenadas osu! a coordenadas SpriteKit
    func toSpriteKitPosition(width: CGFloat, height: CGFloat) -> CGPoint {
        // En osu!, (0,0) es la esquina superior izquierda, en SpriteKit (0,0) es el centro
        let adjustedX = x - width/2
        let adjustedY = height/2 - y
        
        return CGPoint(x: adjustedX, y: adjustedY)
    }
}
