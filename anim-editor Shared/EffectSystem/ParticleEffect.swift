//
//  ParticleEffect.swift
//  anim-editor
//
//  Created by José Puma on 16-04-25.
//

import SpriteKit

/// Efecto base para sistemas de partículas
class ParticleEffect: Effect {
    private var emitter: ParticleEmitter?
    private var settings: ParticleEmitterSettings
    
    init(name: String, settings: ParticleEmitterSettings) {
        self.settings = settings
        super.init(name: name, parameters: [:])
        
        // Convertir los ajustes a parámetros para UI
        updateParametersFromSettings()
    }
    
    override func apply(to spriteManager: SpriteManager, in scene: SKScene) {
        // Limpiar emisor anterior si existe
        if let existingEmitter = emitter {
            existingEmitter.cleanup()
        }
        
        // Actualizar configuración desde los parámetros UI
        updateSettingsFromParameters()
        
        // Crear nuevo emisor
        emitter = ParticleEmitter(spriteManager: spriteManager, settings: settings)
        emitter?.apply(in: scene)
    }
    
    override func removeSprites(from spriteManager: SpriteManager) {
        emitter?.cleanup()
        emitter = nil
        super.removeSprites(from: spriteManager)
    }
    
    // Convierte los settings a parámetros para mostrar en UI
    private func updateParametersFromSettings() {
        parameters["startTime"] = settings.startTime
        parameters["endTime"] = settings.endTime
        parameters["particleCount"] = settings.particleCount
        parameters["emissionMode"] = emissionModeToString(settings.emissionMode)
        parameters["fadeOutAtEnd"] = settings.fadeOutAtEnd
        parameters["lifetime_min"] = settings.lifetime.min
        parameters["lifetime_max"] = settings.lifetime.max
        parameters["velocity_min"] = settings.initialVelocity.min
        parameters["velocity_max"] = settings.initialVelocity.max
        parameters["wind_effect"] = settings.windEffect
        parameters["turbulence"] = settings.turbulence
        parameters["is_additive"] = settings.isAdditive
        
        // Convertir shape a parámetros
        switch settings.emissionShape {
        case .point(let position):
            parameters["emissionShape"] = "point"
            parameters["positionX"] = position.x
            parameters["positionY"] = position.y
            
        case .line(let start, let end):
            parameters["emissionShape"] = "line"
            parameters["startX"] = start.x
            parameters["startY"] = start.y
            parameters["endX"] = end.x
            parameters["endY"] = end.y
            
        case .circle(let center, let radius):
            parameters["emissionShape"] = "circle"
            parameters["centerX"] = center.x
            parameters["centerY"] = center.y
            parameters["radius"] = radius
            
        case .rectangle(let rect):
            parameters["emissionShape"] = "rectangle"
            parameters["rectX"] = rect.origin.x
            parameters["rectY"] = rect.origin.y
            parameters["rectWidth"] = rect.width
            parameters["rectHeight"] = rect.height
        }
    }
    
    // Actualiza los settings basado en los parámetros editados en la UI
    private func updateSettingsFromParameters() {
        settings.startTime = parameters["startTime"] as? Int ?? settings.startTime
        settings.endTime = parameters["endTime"] as? Int ?? settings.endTime
        settings.particleCount = parameters["particleCount"] as? Int ?? settings.particleCount
        settings.emissionMode = stringToEmissionMode(parameters["emissionMode"] as? String ?? "")
        settings.fadeOutAtEnd = parameters["fadeOutAtEnd"] as? Bool ?? settings.fadeOutAtEnd
        settings.isAdditive = parameters["is_additive"] as? Bool ?? settings.isAdditive
        
        // Actualizar rangos
        if let min = parameters["lifetime_min"] as? Int,
           let max = parameters["lifetime_max"] as? Int {
            settings.lifetime = ValueRange(min: min, max: max)
        }
        
        if let min = parameters["velocity_min"] as? CGFloat,
           let max = parameters["velocity_max"] as? CGFloat {
            settings.initialVelocity = ValueRange(min: min, max: max)
        }
        
        if let isAdditiveString = parameters["is_additive"] as? String, let addvAL = Bool(isAdditiveString) {
            settings.isAdditive = Bool(addvAL)
        }
        
        if let windStr = parameters["wind_effect"] as? String, let windVal = Double(windStr) {
            settings.windEffect = CGFloat(windVal)
        }
        
        if let turbStr = parameters["turbulence"] as? String, let turbVal = Double(turbStr) {
            settings.turbulence = CGFloat(turbVal)
        }
        
        // Actualizar forma de emisión
        let shapeType = parameters["emissionShape"] as? String ?? "point"
        
        switch shapeType {
        case "point":
            let x = parameters["positionX"] as? CGFloat ?? 0
            let y = parameters["positionY"] as? CGFloat ?? 0
            settings.emissionShape = .point(position: CGPoint(x: x, y: y))
            
        case "line":
            let startX = parseCGFloat(parameters["startX"])
            let startY = parseCGFloat(parameters["startY"])
            let endX = parseCGFloat(parameters["endX"])
            let endY = parseCGFloat(parameters["endY"])
            
            print(startX, startY, endX, endY)
            settings.emissionShape = .line(
                start: CGPoint(x: startX, y: startY),
                end: CGPoint(x: endX, y: endY)
            )
            
        case "circle":
            let centerX = parameters["centerX"] as? CGFloat ?? 0
            let centerY = parameters["centerY"] as? CGFloat ?? 0
            let radius = parameters["radius"] as? CGFloat ?? 50
            
            settings.emissionShape = .circle(
                center: CGPoint(x: centerX, y: centerY),
                radius: radius
            )
            
        case "rectangle":
            let rectX = parameters["rectX"] as? CGFloat ?? 0
            let rectY = parameters["rectY"] as? CGFloat ?? 0
            let width = parameters["rectWidth"] as? CGFloat ?? 100
            let height = parameters["rectHeight"] as? CGFloat ?? 100
            
            settings.emissionShape = .rectangle(
                rect: CGRect(x: rectX, y: rectY, width: width, height: height)
            )
            
        default:
            settings.emissionShape = .point(position: CGPoint.zero)
        }
    }
    
    private func parseCGFloat(_ value: Any?) -> CGFloat {
        if let number = value as? CGFloat {
            return number
        } else if let number = value as? Double {
            return CGFloat(number)
        } else if let number = value as? Float {
            return CGFloat(number)
        } else if let number = value as? Int {
            return CGFloat(number)
        } else if let str = value as? String, let doubleVal = Double(str) {
            return CGFloat(doubleVal)
        }
        return 0 // Valor por defecto si no se pudo convertir
    }
    
    // Helpers para convertir entre enum y string
    private func emissionModeToString(_ mode: EmissionMode) -> String {
        switch mode {
        case .continuous: return "continuous"
        case .burst: return "burst"
        case .controlled: return "controlled"
        }
    }
    
    private func stringToEmissionMode(_ string: String) -> EmissionMode {
        switch string {
        case "continuous": return .continuous
        case "burst": return .burst
        case "controlled": return .controlled
        default: return .continuous
        }
    }
}
