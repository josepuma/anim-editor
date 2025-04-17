//
//  ParticlePresets.swift
//  anim-editor
//
//  Created by José Puma on 16-04-25.
//

import SpriteKit

// Función auxiliar interna para convertir coordenadas
fileprivate func convertCoordinates(x: CGFloat, y: CGFloat) -> CGPoint {
    // Convertir de coordenadas de usuario (0,0 en esquina superior izquierda, 320,240 centro)
    // a coordenadas SpriteKit (0,0 en el centro)
    let spriteKitX = x - 320
    let spriteKitY = 240 - y
    return CGPoint(x: spriteKitX, y: spriteKitY)
}

// MARK: - Efecto de Lluvia
class RainParticleEffect: ParticleEffect {
    init(texture: SKTexture, startTime: Int = 0, endTime: Int = 10000, intensity: Int = 50, windEffect: CGFloat = 10, turbulence: CGFloat = 5) {
        var settings = ParticleEmitterSettings(texture: texture)
        
        // Configuración específica para lluvia
        settings.startTime = startTime
        settings.endTime = endTime
        settings.particleCount = intensity
        settings.emissionMode = .continuous
        
        // Coordenadas convertidas:
        let leftX = -127 // 0 - 320
        let rightX = 720 // 854 - 320
        let topY = -20 // 240 - 0 = 240
        let bottomY = 0
        
        settings.emissionShape = .line(
            start: CGPoint(x: leftX, y: topY),
            end: CGPoint(x: rightX, y: bottomY)
        )
        
        // Activar movimiento por ejes separados para mayor control
          settings.useSeparateAxisMovement = true
          
          // Velocidad vertical (hacia abajo) - valores positivos para velocidad Y
          settings.velocityRangeY = ValueRange(min: 150, max: 300)
          
          // Velocidad horizontal ligera para variación
          settings.velocityRangeX = ValueRange(min: -20, max: 20)
          
          // Añadir efecto de viento sutil
          settings.windEffect = windEffect
          
          // Tiempo de vida - lo suficiente para caer por toda la pantalla
          settings.lifetime = ValueRange(min: 2000, max: 3500)
          
          // Usar escala no uniforme para gotas de lluvia más realistas (más altas que anchas)
          settings.useScaleVec = true
          settings.initialScaleX = ValueRange(min: 0.01, max: 0.04)     // Más estrecho en X
          settings.initialScaleY = ValueRange(min: 1.5, max: 4.0)     // Más alto en Y
          
          // Propiedades visuales
          settings.initialAlpha = ValueRange(min: 0.6, max: 0.9)
          settings.initialRotation = ValueRange(fixed: 0)  // Sin rotación inicial
          
          // Opciones de animación
          settings.fadeOutAtEnd = true
          settings.useRandomEasing = false
          
          // Añadir turbulencia sutil para movimiento menos predecible
          settings.turbulence = turbulence
          
          super.init(name: "Rain", settings: settings)
    }
}

// MARK: - Efecto de Nieve
class SnowParticleEffect: ParticleEffect {
    init(texture: SKTexture, startTime: Int = 0, endTime: Int = 10000, intensity: Int = 40) {
        var settings = ParticleEmitterSettings(texture: texture)
        
        // Configuración básica
        settings.startTime = startTime
        settings.endTime = endTime
        settings.particleCount = intensity
        settings.emissionMode = .continuous
        
        // Área de emisión en la parte superior de la pantalla
        let startX = -127 // 0 - 320
        let endX = 720 // 854 - 320
        let topY = -20 // 240 - 0 = 240
        
        settings.emissionShape = .line(
            start: CGPoint(x: startX, y: topY),
            end: CGPoint(x: endX, y: topY)
        )
        
        // Activar movimiento por ejes separados
        settings.useSeparateAxisMovement = true
        
        // Movimiento lento hacia abajo
        settings.velocityRangeY = ValueRange(min: 30, max: 60)
        
        // Movimiento horizontal zigzagueante
        settings.velocityRangeX = ValueRange(min: -40, max: 40)
        
        // Efectos adicionales
        settings.windEffect = 15    // Más efecto de viento que la lluvia
        settings.turbulence = 15    // Alta turbulencia para movimiento aleatorio
        
        // Tiempo de vida más largo
        settings.lifetime = ValueRange(min: 4000, max: 8000)
        
        // Usar escala uniforme para copos de nieve
        settings.useScaleVec = false
        settings.initialScale = ValueRange(min: 0.1, max: 0.3)
        
        // Propiedades visuales
        settings.initialAlpha = ValueRange(min: 0.7, max: 1.0)
        settings.initialRotation = ValueRange(min: 0, max: 360)
        
        // Opciones de animación
        settings.fadeOutAtEnd = true
        settings.rotateOverLifetime = true
        settings.useRandomEasing = true
        
        super.init(name: "Snow", settings: settings)
    }
}

// MARK: - Efecto de Explosión
class ExplosionParticleEffect: ParticleEffect {
    init(texture: SKTexture, position: CGPoint, startTime: Int = 0, intensity: Int = 80) {
        var settings = ParticleEmitterSettings(texture: texture)
        
        // Convertir posición del sistema de usuario a SpriteK
        
        // Configuración específica para explosión
        settings.startTime = startTime
        settings.endTime = startTime + 100 // Explosión instantánea
        settings.particleCount = intensity
        settings.emissionMode = .burst
        
        // Emisión desde un punto central
        settings.emissionShape = .point(position: position)
        
        // Velocidad radial alta
        settings.initialVelocity = ValueRange(min: 200, max: 400)
        settings.initialDirection = ValueRange(min: 0, max: 360)
        
        // Tiempo de vida corto a medio
        settings.lifetime = ValueRange(min: 800, max: 1500)
        
        // Propiedades visuales
        settings.initialScale = ValueRange(min: 0.1, max: 1)
        settings.initialAlpha = ValueRange(min: 0.8, max: 1.0)
        settings.initialRotation = ValueRange(min: 0, max: 360)
        settings.initialColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0) // Color amarillento para explosión
        
        // Opciones de animación
        settings.fadeOutAtEnd = true
        settings.scaleOverLifetime = true
        settings.rotateOverLifetime = true
        settings.useRandomEasing = true // Usamos diferentes easings para movimiento dinámico
        
        super.init(name: "Explosion", settings: settings)
    }
}

// MARK: - Efecto de Destellos/Chispas
class SparkleParticleEffect: ParticleEffect {
    init(texture: SKTexture, position: CGPoint, startTime: Int = 0, endTime: Int = 5000, intensity: Int = 30) {
        var settings = ParticleEmitterSettings(texture: texture)
        
        // Convertir posición del sistema de usuario a SpriteKit
        
        // Configuración específica para destellos
        settings.startTime = startTime
        settings.endTime = endTime
        settings.particleCount = intensity
        settings.emissionMode = .continuous
        
        // Área de emisión circular
        settings.emissionShape = .circle(
            center: position,
            radius: 50
        )
        
        // Velocidad baja a media con dirección variada
        settings.initialVelocity = ValueRange(min: 5, max: 40)
        settings.initialDirection = ValueRange(min: 0, max: 360)
        
        // Tiempo de vida medio
        settings.lifetime = ValueRange(min: 1000, max: 3000)
        
        // Propiedades visuales
        settings.initialScale = ValueRange(min: 0.5, max: 1.0)
        settings.initialAlpha = ValueRange(min: 0.6, max: 1.0)
        settings.initialRotation = ValueRange(min: 0, max: 360)
        settings.initialColor = SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0) // Color brillante
        
        // Opciones de animación
        settings.fadeOutAtEnd = true
        settings.scaleOverLifetime = true
        settings.useRandomEasing = true
        
        super.init(name: "Sparkle", settings: settings)
    }
}

// MARK: - Efecto de Humo
class SmokeParticleEffect: ParticleEffect {
    init(texture: SKTexture, position: CGPoint, startTime: Int = 0, endTime: Int = 10000, intensity: Int = 30) {
        var settings = ParticleEmitterSettings(texture: texture)
        
        // Convertir posición del sistema de usuario a SpriteKit

        
        // Configuración específica para humo
        settings.startTime = startTime
        settings.endTime = endTime
        settings.particleCount = intensity
        settings.emissionMode = .continuous
        
        // Emisión desde un punto o área pequeña
        settings.emissionShape = .circle(
            center: position,
            radius: 10
        )
        
        // Velocidad lenta ascendente
        settings.initialVelocity = ValueRange(min: 10, max: 30)
        settings.initialDirection = ValueRange(min: 60, max: 120)
        
        // Tiempo de vida largo
        settings.lifetime = ValueRange(min: 3000, max: 7000)
        
        // Propiedades visuales
        settings.initialScale = ValueRange(min: 0.5, max: 1.0)
        settings.initialAlpha = ValueRange(min: 0.3, max: 0.7)
        settings.initialRotation = ValueRange(min: 0, max: 360)
        settings.initialColor = SKColor(white: 0.8, alpha: 1.0) // Color grisáceo para humo
        
        // Opciones de animación
        settings.fadeOutAtEnd = true
        settings.scaleOverLifetime = true
        settings.rotateOverLifetime = true
        settings.useRandomEasing = false // Easing lineal para movimiento de humo más natural
        
        super.init(name: "Smoke", settings: settings)
    }
}

// MARK: - Efecto de Burbujas
class BubbleParticleEffect: ParticleEffect {
    init(texture: SKTexture, position: CGPoint, startTime: Int = 0, endTime: Int = 10000, intensity: Int = 25) {
        var settings = ParticleEmitterSettings(texture: texture)
        
        
        // Calcular puntos de la línea de emisión
        let startX = position.x - 100
        let endX = position.x + 100
        
        // Configuración para burbujas
        settings.startTime = startTime
        settings.endTime = endTime
        settings.particleCount = intensity
        settings.emissionMode = .continuous
        
        // Área de emisión en línea horizontal (como burbujas subiendo del fondo)
        settings.emissionShape = .line(
            start: CGPoint(x: startX, y: position.y),
            end: CGPoint(x: endX, y: position.y)
        )
        
        // Movimiento lento hacia arriba con ligero balanceo
        settings.initialVelocity = ValueRange(min: 20, max: 50)
        settings.initialDirection = ValueRange(min: 70, max: 110)
        
        // Tiempo de vida medio-largo
        settings.lifetime = ValueRange(min: 2000, max: 5000)
        
        // Propiedades visuales - burbujas variadas
        settings.initialScale = ValueRange(min: 0.3, max: 1.2)
        settings.initialAlpha = ValueRange(min: 0.4, max: 0.8)
        settings.initialColor = SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0) // Color azulado transparente
        
        // Opciones de animación
        settings.fadeOutAtEnd = true
        settings.scaleOverLifetime = true // Las burbujas crecen ligeramente
        settings.useRandomEasing = true // Movimiento natural variable
        
        super.init(name: "Bubbles", settings: settings)
    }
}

// MARK: - Efecto de Fuego
class FireParticleEffect: ParticleEffect {
    init(texture: SKTexture, position: CGPoint, startTime: Int = 0, endTime: Int = 10000, intensity: Int = 60) {
        var settings = ParticleEmitterSettings(texture: texture)
    
        
        // Configuración para fuego
        settings.startTime = startTime
        settings.endTime = endTime
        settings.particleCount = intensity
        settings.emissionMode = .continuous
        // Área de emisión en línea horizontal (base del fuego)
        settings.emissionShape = .line(
            start: CGPoint(x: position.x - 30, y: position.y),
            end: CGPoint(x: position.x + 30, y: position.y)
        )
        
        // Movimiento ascendente rápido
        settings.initialVelocity = ValueRange(min: 50, max: 120)
        settings.initialDirection = ValueRange(min: 80, max: 100)
        
        // Tiempo de vida corto (las llamas se consumen rápido)
        settings.lifetime = ValueRange(min: 800, max: 1500)
        
        // Propiedades visuales
        settings.initialScale = ValueRange(min: 0.1, max: 1)
        settings.initialAlpha = ValueRange(min: 0.7, max: 1.0)
        settings.initialRotation = ValueRange(min: -10, max: 10)
        settings.initialColor = SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 1.0) // Color naranja-rojizo
        
        // Opciones de animación
        settings.fadeOutAtEnd = true
        settings.scaleOverLifetime = true // Las llamas crecen y se desvanecen
        settings.rotateOverLifetime = false
        settings.useRandomEasing = true
        
        super.init(name: "Fire", settings: settings)
    }
}
