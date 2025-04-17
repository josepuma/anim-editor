//
//  CustomParticleEffect.swift
//  anim-editor
//
//  Created by José Puma on 16-04-25.
//

import SpriteKit

/// Efecto de partículas personalizable
/// Permite crear cualquier tipo de efecto con parámetros específicos
class CustomParticleEffect: ParticleEffect {
    init(name: String, texture: SKTexture, config: (inout ParticleEmitterSettings) -> Void) {
        // Crear configuración base con valores predeterminados
        var settings = ParticleEmitterSettings(texture: texture)
        
        // Permitir que el caller configure los ajustes específicos
        config(&settings)
        
        // Inicializar con la configuración personalizada
        super.init(name: name, settings: settings)
    }
}

/// Extensión de ParticleManager para crear efectos personalizados
extension ParticleManager {
    /// Crea un efecto de partículas personalizado
    /// - Parameters:
    ///   - name: Nombre del efecto
    ///   - textureName: Nombre del archivo de textura
    ///   - config: Closure para configurar los parámetros del emisor
    /// - Returns: El efecto creado o nil si no se pudo cargar la textura
    func createCustomEffect(
        name: String,
        textureName: String,
        config: @escaping (inout ParticleEmitterSettings) -> Void
    ) -> ParticleEffect? {
        guard let texture = textureLoader.getTexture(named: textureName) else {
            print("Error: No se pudo cargar la textura para efecto personalizado")
            return nil
        }
        
        let effect = CustomParticleEffect(name: name, texture: texture, config: config)
        effects.append(effect)
        effect.apply(to: spriteManager, in: scene)
        return effect
    }
}

// MARK: - Ejemplos de uso
/*
 // Ejemplo de cómo crear un efecto personalizado:
 
 let customEffect = particleManager.createCustomEffect(
     name: "Estrellas",
     textureName: "star.png"
 ) { settings in
     // Configurar tiempo
     settings.startTime = currentTime
     settings.endTime = currentTime + 10000
     
     // Configurar emisión
     settings.emissionMode = .continuous
     settings.particleCount = 30
     settings.emissionShape = .circle(center: CGPoint(x: 0, y: 0), radius: 200)
     
     // Configurar comportamiento
     settings.initialVelocity = ValueRange(min: 10, max: 20)
     settings.initialDirection = ValueRange(min: 0, max: 360)
     settings.lifetime = ValueRange(min: 2000, max: 5000)
     
     // Configurar apariencia
     settings.initialScale = ValueRange(min: 0.5, max: 1.5)
     settings.initialAlpha = ValueRange(min: 0.5, max: 1.0)
     settings.initialColor = .yellow
     
     // Configurar animaciones
     settings.fadeOutAtEnd = true
     settings.scaleOverLifetime = true
     settings.rotateOverLifetime = true
     settings.useRandomEasing = true
 }
 */
