//
//  OsuHitObject.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

import SpriteKit

class OsuHitObject {
    var position: OsuPoint
    var time: Int // milisegundos
    var type: OsuHitObjectType
    var newCombo: Bool
    var comboColorOffset: Int
    var hitsoundType: Int
    var extras: [String: String] = [:]
    var hitSample: HitSoundManager.HitSampleInfo = HitSoundManager.HitSampleInfo()
    
    init(position: OsuPoint, time: Int, type: OsuHitObjectType, newCombo: Bool, comboColorOffset: Int, hitsoundType: Int) {
        self.position = position
        self.time = time
        self.type = type
        self.newCombo = newCombo
        self.comboColorOffset = comboColorOffset
        self.hitsoundType = hitsoundType
    }
    
    // Crear representación de sprite para este objeto
    func createSprite(circleTexture: SKTexture, approachTexture: SKTexture) -> Sprite {
        fatalError("Las subclases deben implementar createSprite")
    }
}
