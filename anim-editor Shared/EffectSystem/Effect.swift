//
//  Effect.swift
//  anim-editor
//
//  Created by José Puma on 31-12-24.
//

import SpriteKit

class Effect {
    var name: String
    var parameters: [String: Any]
    var sprites: [Sprite] = []

    init(name: String, parameters: [String: Any]) {
        self.name = name
        self.parameters = parameters
    }

    func apply(to spriteManager: SpriteManager, in scene: SKScene) {
        // Override in subclasses to apply the effect
    }
    
    func removeSprites(from spriteManager: SpriteManager) {
        for sprite in sprites {
            spriteManager.removeSprite(sprite)
        }
        sprites.removeAll()
    }
}
