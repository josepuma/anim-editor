//
//  ParticleAPIExport.swift
//  anim-editor
//
//  Created by José Puma on 17-04-25.
//

import JavaScriptCore
import SpriteKit

// 1. Definir un protocolo que extienda JSExport con todos los métodos que necesitamos
@objc protocol ParticleAPIExport: JSExport {
    func createSprite(_ texturePath: String) -> JSValue
    func clearEffects()
    func getCurrentTime() -> Int
    func random(_ min: Double, _ max: Double) -> Double
    func randomInt(_ min: Int, _ max: Int) -> Int
}

// 2. Implementar una clase que conforme a este protocolo
@objc class ParticleAPIBridge: NSObject, ParticleAPIExport {
    weak var interpreter: JSInterpreter?
    weak var particleManager: ParticleManager?
    weak var scene: SKScene?
    
    init(interpreter: JSInterpreter, particleManager: ParticleManager, scene: SKScene) {
        self.interpreter = interpreter
        self.particleManager = particleManager
        self.scene = scene
        super.init()
    }
    
    func getEasingFromString(_ string: String) -> Easing {
           // Si tienes acceso al método del intérprete, úsalo
           if let easing = interpreter?.getEasingFromString(string) {
               return easing
           }
           
           // De lo contrario, implementa la lógica aquí
           switch string.lowercased() {
           case "linear": return .linear
           case "easein", "easing_in": return .easingIn
           case "easeout", "easing_out": return .easingOut
           // Añade aquí todos los casos necesarios...
           default: return .linear
           }
       }
    
    func createSprite(_ texturePath: String) -> JSValue {
        guard let context = JSContext.current(),
              let particleManager = particleManager,
              let texture = particleManager.textureLoader.getTexture(named: texturePath) else {
            print("❌ ERROR: No se pudo crear sprite con textura: \(texturePath)")
            return JSValue(nullIn: JSContext.current())
        }
        
        // Crear sprite
        let sprite = Sprite(texture: texture)
        
        // Añadir a lista de sprites del script
        if let scriptId = interpreter?.currentScriptId { // Usa interpreter?.currentScriptId
                interpreter?.addSpriteToScript(scriptId: scriptId, sprite: sprite)
            }
        
        // Crear objeto JS para el sprite
        let spriteObj = JSValue(newObjectIn: context)
        
        // Añadir métodos directamente al objeto sprite
        // addFadeTween
        let addFadeTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self.getEasingFromString(easingStr)
            sprite.addFadeTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        spriteObj?.setValue(addFadeTween, forProperty: "addFadeTween")
        
        // addMoveXTween
        let addMoveXTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self.getEasingFromString(easingStr)
            sprite.addMoveXTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        spriteObj?.setValue(addMoveXTween, forProperty: "addMoveXTween")
        
        
        let addMoveYTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self.getEasingFromString(easingStr)
            sprite.addMoveYTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        spriteObj?.setValue(addMoveYTween, forProperty: "addMoveYTween")
        
        
        // Añade todos los demás métodos directamente al objeto sprite...
        
        // addMoveTween
        let addMoveTween: @convention(block) (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startX, startY, endX, endY, easingStr) in
            let easing = self.getEasingFromString(easingStr)
            sprite.addMoveTween(easing: easing, startTime: startTime, endTime: endTime,
                              startValue: CGPoint(x: startX, y: startY),
                              endValue: CGPoint(x: endX, y: endY))
        }
        spriteObj?.setValue(addMoveTween, forProperty: "addMoveTween")

        
        // addScaleTween
        let addScaleTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self.getEasingFromString(easingStr)
            sprite.addScaleTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        spriteObj?.setValue(addScaleTween, forProperty: "addScaleTween")
        
        let addRotateTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self.getEasingFromString(easingStr)
            sprite.addRotateTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        spriteObj?.setValue(addRotateTween, forProperty: "addRotateTween")
        
        let addBlendMode: @convention(block) (Int, Int) -> Void = { (startTime, endTime) in
            sprite.addBlendModeTween(startTime: startTime, endTime: endTime)
        }
        spriteObj?.setValue(addBlendMode, forProperty: "addBlendMode")
        
        // setPosition
        let setPosition: @convention(block) (CGFloat, CGFloat) -> Void = { (x, y) in
            sprite.setInitialPosition(position: CGPoint(x: x, y: y))
        }
        spriteObj?.setValue(setPosition, forProperty: "setPosition")
        
        // startLoop y endLoop
        let startLoop: @convention(block) (Int, Int) -> Void = { (startTime, loopCount) in
            sprite.startLoop(startTime: startTime, loopCount: loopCount)
        }
        spriteObj?.setValue(startLoop, forProperty: "startLoop")
        
        let endLoop: @convention(block) () -> Void = {
            sprite.endLoop()
        }
        spriteObj?.setValue(endLoop, forProperty: "endLoop")
        
        // Añadir sprite al manager
        particleManager.spriteManager.addSprite(sprite)
        
        return spriteObj!
    }
    
    func clearEffects() {
        guard let interpreter = interpreter,
              let scriptId = interpreter.currentScriptId,
              let particleManager = particleManager else {
            return
        }
        
        interpreter.clearScriptSprites(scriptId: scriptId, spriteManager: particleManager.spriteManager)
    }
    
    func getCurrentTime() -> Int {
        guard let scene = scene as? GameScene,
              let audioPlayer = scene.audioPlayer else {
            return 0
        }
        return Int(audioPlayer.currentTime * 1000)
    }
    
    func random(_ min: Double, _ max: Double) -> Double {
        return Double.random(in: min...max)
    }
    
    func randomInt(_ min: Int, _ max: Int) -> Int {
        return Int.random(in: min...max)
    }
}

// 3. También necesitamos un Bridge para Sprite
@objc protocol SpriteExport: JSExport {
    func addMoveXTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String)
    func addMoveYTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String)
    func addMoveTween(_ startTime: Int, _ endTime: Int, _ startX: CGFloat, _ startY: CGFloat, _ endX: CGFloat, _ endY: CGFloat, _ easingStr: String)
    func addScaleTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String)
    func addFadeTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String)
    func addBlendMode(_startTime: Int, _endTime: Int)
    // Añadir el resto de métodos del sprite...
    func setPosition(_ x: CGFloat, _ y: CGFloat)
    func startLoop(_ startTime: Int, _ loopCount: Int)
    func endLoop()
}

@objc class SpriteBridge: NSObject, SpriteExport {
    var sprite: Sprite
    weak var interpreter: JSInterpreter?
    
    init(sprite: Sprite, interpreter: JSInterpreter?) {
        self.sprite = sprite
        self.interpreter = interpreter
        super.init()
    }
    
    func addMoveXTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String) {
        let easing = interpreter?.getEasingFromString(easingStr) ?? .linear
        sprite.addMoveXTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }
    
    func addMoveYTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String) {
        let easing = interpreter?.getEasingFromString(easingStr) ?? .linear
        sprite.addMoveYTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }
    
    func addMoveTween(_ startTime: Int, _ endTime: Int, _ startX: CGFloat, _ startY: CGFloat, _ endX: CGFloat, _ endY: CGFloat, _ easingStr: String) {
        let easing = interpreter?.getEasingFromString(easingStr) ?? .linear
        sprite.addMoveTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGPoint(x: startX, y: startY), endValue: CGPoint(x: endX, y: endY))
    }
    
    func addScaleTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String) {
        let easing = interpreter?.getEasingFromString(easingStr) ?? .linear
        sprite.addScaleTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }
    
    func addFadeTween(_ startTime: Int, _ endTime: Int, _ startValue: CGFloat, _ endValue: CGFloat, _ easingStr: String) {
        let easing = interpreter?.getEasingFromString(easingStr) ?? .linear
        sprite.addScaleTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }
    
    func addBlendMode(_startTime: Int, _endTime: Int) {
        sprite.addBlendModeTween(startTime: _startTime, endTime: _endTime)
    }
    
    // Implementar el resto de métodos del sprite...
    
    func setPosition(_ x: CGFloat, _ y: CGFloat) {
        sprite.setInitialPosition(position: CGPoint(x: x, y: y))
    }
    
    func startLoop(_ startTime: Int, _ loopCount: Int) {
        sprite.startLoop(startTime: startTime, loopCount: loopCount)
    }
    
    func endLoop() {
        sprite.endLoop()
    }
}
