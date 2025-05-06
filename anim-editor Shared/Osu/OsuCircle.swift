//
//  OsuCircle.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

import SpriteKit

class OsuCircle: OsuHitObject {
    override func createSprite(circleTexture: SKTexture, approachTexture: SKTexture) -> Sprite {
        let sprite = Sprite(texture: circleTexture)
        
        // Configurar posición inicial
        sprite.setInitialPosition(position: position.toSpriteKitPosition(width: 640, height: 480))
        
        // Estado inicial (invisible y pequeño)
        /*sprite.addScaleTween(easing: .sineOut,
                           startTime: time - 800, // aparecer 800ms antes del tiempo de hit
                           endTime: time - 800,
                           startValue: 0,
                           endValue: 0)*/
        
        // Animación de aparecer
        sprite.addFadeTween(easing: .sineOut,
                          startTime: time - 800,
                          endTime: time - 600,
                          startValue: 0,
                          endValue: 1)
        
        sprite.addScaleTween(easing: .sineOut,
                           startTime: time - 800,
                           endTime: time - 600,
                           startValue: 0.1,
                             endValue: 0.65)
        
        // Permanecer visible hasta el tiempo de hit
        sprite.addFadeTween(easing: .linear,
                          startTime: time - 600,
                          endTime: time,
                          startValue: 1,
                          endValue: 1)
        
        // Desvanecer después del tiempo de hit
        sprite.addFadeTween(easing: .sineIn,
                          startTime: time,
                          endTime: time + 200,
                          startValue: 1,
                          endValue: 0)
        
        return sprite
    }
    
    // Crear un sprite separado para el approach circle
    func createApproachSprite(approachTexture: SKTexture) -> Sprite {
        let approachSprite = Sprite(texture: approachTexture)
        approachSprite.setInitialPosition(position: position.toSpriteKitPosition(width: 640, height: 480))
        
        // Estado inicial (grande y semitransparente)
        /*approachSprite.addScaleTween(easing: .linear,
                                   startTime: time - 800,
                                   endTime: time - 800,
                                   startValue: 3,
                                   endValue: 3)*/
        
        approachSprite.addFadeTween(easing: .linear,
                                  startTime: time - 800,
                                  endTime: time - 800,
                                  startValue: 0.6,
                                  endValue: 0.6)
        
        // Animación de acercamiento
        approachSprite.addScaleTween(easing: .linear,
                                   startTime: time - 800,
                                   endTime: time,
                                   startValue: 2,
                                     endValue: 0.65)
        
        // Desvanecer en el tiempo de hit
        approachSprite.addFadeTween(easing: .sineIn,
                                  startTime: time - 200,
                                  endTime: time,
                                  startValue: 0.6,
                                  endValue: 0)
        
        return approachSprite
    }
}
