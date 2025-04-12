//
//  Rain.swift
//  anim-editor
//
//  Created by José Puma on 31-12-24.
//

import SpriteKit

class RainEffect: Effect {
    override func apply(to spriteManager: SpriteManager, in scene: SKScene) {
        guard let texture = parameters["texture"] as? SKTexture else { return }
        let numberOfSprites = parameters["numberOfSprites"] as? Int ?? 50
        let startTime = parameters["startTime"] as? Int ?? 0
        let endTime = parameters["endTime"] as? Int ?? 0
        
        for _ in 0 ..< numberOfSprites {
            //print(numberOfSprites, startTime, endTime)
            let startPosition = Helpers.randomFloatBetween(-127, 720)
            let sprite = Sprite(texture: texture)
            //sprite.addFadeTween(startTime: 0, endTime: 100000, startValue: 1, endValue: 0)
            sprite.addMoveXTween(startTime: startTime, endTime: endTime, startValue: startPosition, endValue: startPosition)
            sprite.addMoveYTween(startTime: startTime, endTime: endTime, startValue: 0, endValue: 480)
            spriteManager.addSprite(sprite)
            sprites.append(sprite)
        }
        
        /*for _ in 0..<50 {
            let startPosition = Helpers.randomFloatBetween(-127, 720)
            let sprite = Sprite(texture: texture)
            sprite.addMoveXTween(startTime: 5000, endTime: 15000, startValue: startPosition, endValue: startPosition)
            sprite.addMoveYTween(startTime: 5000, endTime: 15000, startValue: 0, endValue: 480)
            sprite.addColorTween(startTime: 5000, endTime: 15000, startValue: .red, endValue: .yellow)
            spriteManager.addSprite(sprite)
        }*/
    }
}
