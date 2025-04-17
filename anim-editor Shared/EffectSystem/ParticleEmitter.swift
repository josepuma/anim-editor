//
//  ParticleEmitter.swift
//  anim-editor
//
//  Created by José Puma on 16-04-25.
//

import SpriteKit

/// Definición de las variaciones aplicables a los valores
struct ValueRange<T> {
    var min: T
    var max: T
    
    init(fixed value: T) {
        self.min = value
        self.max = value
    }
    
    init(min: T, max: T) {
        self.min = min
        self.max = max
    }
}

/// Modos de emisión de partículas
enum EmissionMode {
    case continuous // Emite partículas continuamente durante su vida
    case burst      // Emite todas las partículas de una vez
    case controlled // Emite partículas según una curva o tasa variable
}

/// Formas de emisión (donde se generan las partículas)
enum EmissionShape {
    case point(position: CGPoint)
    case line(start: CGPoint, end: CGPoint)
    case circle(center: CGPoint, radius: CGFloat)
    case rectangle(rect: CGRect)
}

/// Configuración del emisor de partículas
struct ParticleEmitterSettings {
        // Propiedades de tiempo
        var startTime: Int = 0
        var endTime: Int = 10000
        
        // Propiedades de emisión
        var emissionMode: EmissionMode = .continuous
        var emissionShape: EmissionShape = .point(position: .zero)
        var particleCount: Int = 50
        var emissionRate: ValueRange<Float> = ValueRange(fixed: 10) // Partículas por segundo
        
        // Propiedades de las partículas
        var texture: SKTexture
        var lifetime: ValueRange<Int> = ValueRange(min: 1000, max: 2000)
        
        // Propiedades físicas iniciales
        var initialVelocity: ValueRange<CGFloat> = ValueRange(min: 50, max: 100)
        var initialDirection: ValueRange<CGFloat> = ValueRange(min: 0, max: 360)
        var gravity: CGFloat = 0.0
        
        // Propiedades visuales
        var initialScale: ValueRange<CGFloat> = ValueRange(fixed: 1.0)
        var initialAlpha: ValueRange<CGFloat> = ValueRange(fixed: 1.0)
        var initialRotation: ValueRange<CGFloat> = ValueRange(fixed: 0.0)
        var initialColor: SKColor = .white
        
        // Tweens predefinidos
        var fadeOutAtEnd: Bool = true
        var scaleOverLifetime: Bool = false
        var rotateOverLifetime: Bool = false
        var useRandomEasing: Bool = false
        
        var useScaleVec: Bool = false
       var initialScaleX: ValueRange<CGFloat> = ValueRange(fixed: 1.0)
       var initialScaleY: ValueRange<CGFloat> = ValueRange(fixed: 1.0)
       var endScaleX: ValueRange<CGFloat>? = nil
       var endScaleY: ValueRange<CGFloat>? = nil
       
       // Propiedades para movimiento separado por ejes
       var useSeparateAxisMovement: Bool = false
       var velocityRangeX: ValueRange<CGFloat>? = nil
       var velocityRangeY: ValueRange<CGFloat>? = nil
       var useGravity: Bool = false
       
       // Propiedades adicionales para más realismo
       var windEffect: CGFloat = 0.0 // Efecto de viento horizontal
       var turbulence: CGFloat = 0.0 // Turbulencia aleatoria en el movimiento
    
    var isAdditive: Bool = true
    
    init(texture: SKTexture) {
        self.texture = texture
    }
}

class ParticleEmitter {
    private var spriteManager: SpriteManager
    private var settings: ParticleEmitterSettings
    private var sprites: [Sprite] = []
    
    init(spriteManager: SpriteManager, settings: ParticleEmitterSettings) {
        self.spriteManager = spriteManager
        self.settings = settings
    }
    
    /// Aplica el emisor en el tiempo especificado
    func apply(in scene: SKScene) {
        // Si es modo burst, emitimos todas las partículas de una vez
        if settings.emissionMode == .burst {
            emitBurst()
        } else {
            // En modo continuo, pre-calculamos todas las partículas
            // pero con tiempos de aparición distribuidos
            emitContinuous()
        }
    }
    
    /// Emite todas las partículas a la vez (modo burst)
    private func emitBurst() {
        let startTime = settings.startTime
        
        for _ in 0..<settings.particleCount {
            let sprite = createParticleSprite(birthTime: startTime)
            sprites.append(sprite)
            spriteManager.addSprite(sprite)
        }
    }
    
    /// Emite partículas continuamente a lo largo del tiempo
    private func emitContinuous() {
        let duration = settings.endTime - settings.startTime
        let totalParticles = settings.particleCount
        
        // Distribuir las partículas a lo largo del tiempo
        for i in 0..<totalParticles {
            // Calcular el tiempo de nacimiento de esta partícula
            let progressFactor = Float(i) / Float(totalParticles)
            let birthTime = settings.startTime + Int(Float(duration) * progressFactor)
            
            let sprite = createParticleSprite(birthTime: birthTime)
            sprites.append(sprite)
            spriteManager.addSprite(sprite)
        }
    }
    
    /// Selecciona un tipo de easing aleatorio
    private func getRandomEasing() -> Easing {
        let easings: [Easing] = [
            .linear, .easingOut, .easingIn
        ]
        
        let randomIndex = Int.random(in: 0..<easings.count)
        return easings[randomIndex]
    }
    
    /// Crea un sprite individual para una partícula
    private func createParticleSprite(birthTime: Int) -> Sprite {
        // Crear sprite con la textura
        let sprite = Sprite(texture: settings.texture)
        // Configurar posición inicial según la forma de emisión
        let initialPosition = generateInitialPosition()
        sprite.setInitialPosition(position: initialPosition)
        
        // Calcular el tiempo de vida de esta partícula
        let lifetime = Int.random(
            in: settings.lifetime.min...settings.lifetime.max
        )
        let deathTime = birthTime + lifetime
        
        // Obtener easing (aleatorio o lineal según configuración)
        let easing = settings.useRandomEasing ? getRandomEasing() : .linear
        
        // Configurar opacity inicial
        let initialAlpha = CGFloat.random(
            in: settings.initialAlpha.min...settings.initialAlpha.max
        )
        sprite.addFadeTween(easing: easing, startTime: birthTime, endTime: birthTime,
                          startValue: 0, endValue: initialAlpha)
        
        // Configurar rotación inicial
        let initialRotation = CGFloat.random(
            in: settings.initialRotation.min...settings.initialRotation.max
        )
        sprite.addRotateTween(easing: easing, startTime: birthTime, endTime: birthTime,
                            startValue: initialRotation, endValue: initialRotation)

        if settings.isAdditive{
            sprite.addBlendModeTween(startTime: birthTime, endTime: birthTime)
        }
        
        // ESCALA: Usar ScaleVec o Scale normal según configuración
        if settings.useScaleVec {
            // Escala separada para X e Y
            let initialScaleX = CGFloat.random(
                in: settings.initialScaleX.min...settings.initialScaleX.max
            )
            let initialScaleY = CGFloat.random(
                in: settings.initialScaleY.min...settings.initialScaleY.max
            )
            
            // Aplicar escala inicial
            sprite.addScaleVecTween(easing: easing, startTime: birthTime, endTime: birthTime,
                                  startValue: CGPoint(x: initialScaleX, y: initialScaleY),
                                  endValue: CGPoint(x: initialScaleX, y: initialScaleY))
            
            // Si está configurado para cambiar escala durante su vida
            if settings.scaleOverLifetime, let endScaleX = settings.endScaleX, let endScaleY = settings.endScaleY {
                let finalScaleX = CGFloat.random(
                    in: endScaleX.min...endScaleX.max
                )
                let finalScaleY = CGFloat.random(
                    in: endScaleY.min...endScaleY.max
                )
                
                sprite.addScaleVecTween(easing: easing, startTime: birthTime, endTime: deathTime,
                                      startValue: CGPoint(x: initialScaleX, y: initialScaleY),
                                      endValue: CGPoint(x: finalScaleX, y: finalScaleY))
            }
        } else {
            // Escala uniforme tradicional
            let initialScale = CGFloat.random(
                in: settings.initialScale.min...settings.initialScale.max
            )
            
            sprite.addScaleTween(easing: easing, startTime: birthTime, endTime: birthTime,
                               startValue: initialScale, endValue: initialScale)
            
            // Si está configurado para cambiar escala durante su vida
            if settings.scaleOverLifetime {
                let endScale = initialScale * 0.1 // Escala final reducida
                sprite.addScaleTween(easing: easing, startTime: birthTime, endTime: deathTime,
                                   startValue: initialScale, endValue: endScale)
            }
        }
        
        // MOVIMIENTO: Usar ejes separados o movimiento direccional según configuración
        if settings.useSeparateAxisMovement {
            // Componentes de velocidad para X e Y por separado
            var velocityX: CGFloat = 0
            var velocityY: CGFloat = 0
            
            // Velocidad X (con efecto de viento si está habilitado)
            if let vRangeX = settings.velocityRangeX {
                velocityX = CGFloat.random(in: vRangeX.min...vRangeX.max)
                velocityX += settings.windEffect // Añadir efecto de viento
            }
            
            // Velocidad Y (con efecto de gravedad si está habilitado)
            if let vRangeY = settings.velocityRangeY {
                velocityY = CGFloat.random(in: vRangeY.min...vRangeY.max)
            }
            
            // Añadir turbulencia si está configurada
            if settings.turbulence > 0 {
                //print(settings.turbulence)
                let turbulenceX = CGFloat.random(in: -settings.turbulence...settings.turbulence)
                let turbulenceY = CGFloat.random(in: -settings.turbulence...settings.turbulence)
                velocityX += turbulenceX
                velocityY += turbulenceY
            }
            
            // Calcular posiciones finales
            let finalX = initialPosition.x + velocityX * CGFloat(lifetime) / 1000.0
            let finalY = initialPosition.y + velocityY * CGFloat(lifetime) / 1000.0
            
            // Aplicar tweens separados por eje
            sprite.addMoveXTween(easing: easing, startTime: birthTime, endTime: deathTime,
                               startValue: initialPosition.x, endValue: finalX)
            
            sprite.addMoveYTween(easing: easing, startTime: birthTime, endTime: deathTime,
                               startValue: initialPosition.y, endValue: finalY)
            
            // Si hay gravedad, añadir un segundo tween para Y con aceleración
            if settings.useGravity && settings.gravity != 0 {
                // Calcular tiempo medio para aplicar aceleración
                let midTime = birthTime + lifetime / 2
                
                // Posición a mitad de tiempo sin gravedad
                let midY = initialPosition.y - (velocityY * CGFloat(lifetime) / 2000.0)
                
                // Posición final con gravedad (aceleración)
                let gravityEffect = settings.gravity * pow(CGFloat(lifetime) / 1000.0, 2) // a * t²
                let finalYWithGravity = finalY - gravityEffect
                
                // Reemplazar el tween Y con dos tweens:
                // 1. De inicio a mitad con velocidad inicial
                sprite.addMoveYTween(easing: .linear, startTime: birthTime, endTime: midTime,
                                   startValue: initialPosition.y, endValue: midY)
                
                // 2. De mitad a final con aceleración (easing cuadrático)
                sprite.addMoveYTween(easing: .quadIn, startTime: midTime, endTime: deathTime,
                                   startValue: midY, endValue: finalYWithGravity)
            }
        } else {
            // Movimiento tradicional basado en dirección y velocidad
            let speed = CGFloat.random(
                in: settings.initialVelocity.min...settings.initialVelocity.max
            )
            
            let angleInDegrees = CGFloat.random(
                in: settings.initialDirection.min...settings.initialDirection.max
            )
            let angle = angleInDegrees * CGFloat.pi / 180.0
            
            let velocityX = cos(angle) * speed
            let velocityY = sin(angle) * speed
            
            // Añadir efecto de viento si está configurado
            let windX = cos(90 * CGFloat.pi / 180.0) * settings.windEffect
            
            // Calcular posición final
            let finalX = initialPosition.x - (velocityX + windX) * CGFloat(lifetime) / 1000.0
            let finalY = initialPosition.y - velocityY * CGFloat(lifetime) / 1000.0
            
            // Movimiento combinado X/Y
            sprite.addMoveTween(easing: easing, startTime: birthTime, endTime: deathTime,
                              startValue: initialPosition,
                              endValue: CGPoint(x: finalX, y: finalY))
        }
        
        // FADE OUT al final de la vida
        if settings.fadeOutAtEnd {
            sprite.addFadeTween(easing: easing, startTime: deathTime - 500, endTime: deathTime,
                              startValue: initialAlpha, endValue: 0)
        }
        
        // ROTACIÓN durante la vida si está habilitado
        if settings.rotateOverLifetime {
            sprite.addRotateTween(easing: easing, startTime: birthTime, endTime: deathTime,
                                startValue: initialRotation, endValue: initialRotation + CGFloat.pi * 2)
        }
        
        // COLOR si es diferente de blanco
        if settings.initialColor != .white {
            sprite.addColorTween(easing: easing, startTime: birthTime, endTime: birthTime,
                               startValue: settings.initialColor, endValue: settings.initialColor)
        }
        
        return sprite
    }
    
    /// Genera una posición inicial basada en la forma de emisión
    private func generateInitialPosition() -> CGPoint {
        switch settings.emissionShape {
        case .point(let position):
            return position
            
        case .line(let start, let end):
            let t = CGFloat.random(in: 0...1)
            return CGPoint(
                x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t
            )
            
        case .circle(let center, let radius):
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 0...radius)
            return CGPoint(
                x: center.x + cos(angle) * distance,
                y: center.y + sin(angle) * distance
            )
            
        case .rectangle(let rect):
            return CGPoint(
                x: CGFloat.random(in: rect.minX...rect.maxX),
                y: CGFloat.random(in: rect.minY...rect.maxY)
            )
        }
    }
    
    /// Limpia todos los sprites creados por este emisor
    func cleanup() {
        for sprite in sprites {
            spriteManager.removeSprite(sprite)
        }
        sprites.removeAll()
    }
    
    /// Obtener los sprites generados por este emisor
    func getSprites() -> [Sprite] {
        return sprites
    }
}
