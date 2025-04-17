//
//  ParticleManager.swift
//  anim-editor
//
//  Created by José Puma on 16-04-25.
//

import SpriteKit

class ParticleManager {
    internal var spriteManager: SpriteManager
    internal var scene: SKScene
    internal var textureLoader: TextureLoader
    internal var effects: [ParticleEffect] = []
    
    init(spriteManager: SpriteManager, scene: SKScene, texturesPath: String) {
        self.spriteManager = spriteManager
        self.scene = scene
        self.textureLoader = TextureLoader(basePath: texturesPath)
    }
    
    // MARK: - Métodos para crear efectos de partículas
    
    func createRainEffect(textureName: String, startTime: Int, endTime: Int, intensity: Int = 50) -> ParticleEffect? {
        guard let texture = textureLoader.getTexture(named: textureName) else {
            print("Error: No se pudo cargar la textura para efecto de lluvia")
            return nil
        }
        
        let effect = RainParticleEffect(
            texture: texture,
            startTime: startTime,
            endTime: endTime,
            intensity: intensity
        )
        effects.append(effect)
        effect.apply(to: spriteManager, in: scene)
        return effect
    }
    
    func createSnowEffect(textureName: String, startTime: Int, endTime: Int, intensity: Int = 40) -> ParticleEffect? {
        guard let texture = textureLoader.getTexture(named: textureName) else {
            print("Error: No se pudo cargar la textura para efecto de nieve")
            return nil
        }
        
        let effect = SnowParticleEffect(
            texture: texture,
            startTime: startTime,
            endTime: endTime,
            intensity: intensity
        )
        effects.append(effect)
        effect.apply(to: spriteManager, in: scene)
        return effect
    }
    
    func createExplosionEffect(textureName: String, position: CGPoint, startTime: Int, intensity: Int = 80) -> ParticleEffect? {
        guard let texture = textureLoader.getTexture(named: textureName) else {
            print("Error: No se pudo cargar la textura para efecto de explosión")
            return nil
        }
        
        let effect = ExplosionParticleEffect(
            texture: texture,
            position: position,
            startTime: startTime,
            intensity: intensity
        )
        effects.append(effect)
        effect.apply(to: spriteManager, in: scene)
        return effect
    }
    
    func createSparkleEffect(textureName: String, position: CGPoint, startTime: Int, endTime: Int, intensity: Int = 30) -> ParticleEffect? {
        guard let texture = textureLoader.getTexture(named: textureName) else {
            print("Error: No se pudo cargar la textura para efecto de destellos")
            return nil
        }
        
        let effect = SparkleParticleEffect(
            texture: texture,
            position: position,
            startTime: startTime,
            endTime: endTime,
            intensity: intensity
        )
        effects.append(effect)
        effect.apply(to: spriteManager, in: scene)
        return effect
    }
    
    func createFireEffect(textureName: String, position: CGPoint, startTime: Int, endTime: Int, intensity: Int = 60) -> ParticleEffect? {
            guard let texture = textureLoader.getTexture(named: textureName) else {
                print("Error: No se pudo cargar la textura para efecto de fuego")
                return nil
            }
            
            let effect = FireParticleEffect(
                texture: texture,
                position: position,
                startTime: startTime,
                endTime: endTime,
                intensity: intensity
            )
            effects.append(effect)
            effect.apply(to: spriteManager, in: scene)
            return effect
        }
        
    
    func createSmokeEffect(textureName: String, position: CGPoint, startTime: Int, endTime: Int, intensity: Int = 30) -> ParticleEffect? {
        guard let texture = textureLoader.getTexture(named: textureName) else {
            print("Error: No se pudo cargar la textura para efecto de humo")
            return nil
        }
        
        let effect = SmokeParticleEffect(
            texture: texture,
            position: position,
            startTime: startTime,
            endTime: endTime,
            intensity: intensity
        )
        effects.append(effect)
        effect.apply(to: spriteManager, in: scene)
        return effect
    }
    
    func removeAllEffects() {
        for effect in effects {
            effect.removeSprites(from: spriteManager)
        }
        effects.removeAll()
    }
    
    func getEffects() -> [ParticleEffect] {
        return effects
    }
}

// Clase auxiliar para cargar y cachear texturas, similar a SpriteParser
class TextureLoader {
    private var basePath: String
    private var textureCache: [String: SKTexture] = [:]
    
    init(basePath: String) {
        self.basePath = basePath
    }
    
    func getTexture(named textureName: String) -> SKTexture? {
        // Check if the texture is already in the cache
        if let cachedTexture = textureCache[textureName] {
            return cachedTexture
        }
        
        // If not, load it from the file path
        if let texture = Texture.textureFromLocalPath("\(basePath)/\(textureName)") {
            textureCache[textureName] = texture
            return texture
        }
        
        // If the texture could not be loaded, return nil
        return nil
    }
    
    func preloadTextures(names: [String]) {
        for name in names {
            _ = getTexture(named: name)
        }
    }
    
    func clearCache() {
        textureCache.removeAll()
    }
}
