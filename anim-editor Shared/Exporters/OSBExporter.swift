//
//  OSBExporter.swift
//  anim-editor
//
//  Created by José Puma on 11-05-25.
//


import Foundation
import SpriteKit

class OSBExporter {
    // Función principal para exportar a formato .osb
    func exportToOSB(scriptManager: ParticleScriptManager, outputPath: String) -> Bool {
        var osbContent = "[Events]\n//Background and Video events\n//Storyboard Layer 0 (Background)\n//Storyboard Layer 1 (Fail)\n//Storyboard Layer 2 (Pass)\n//Storyboard Layer 3 (Foreground)\n"
        
        let sceneDictionaries = scriptManager.getScriptScenes()

        // Combinar todos los ScriptScenes en un solo array
        let allScenes = sceneDictionaries.compactMap { $0 } // eliminar nils si hay
            .compactMap { $0.value }

        // Ordenarlos según scriptExecutionOrder
        let orderedScenes = allScenes.sorted { first, second in
            guard let firstIndex = scriptManager.scriptExecutionOrder.firstIndex(of: first.scriptName),
                  let secondIndex = scriptManager.scriptExecutionOrder.firstIndex(of: second.scriptName) else {
                return false
            }
            return firstIndex < secondIndex
        }

        // Ahora iterar sobre las escenas en orden
        for scriptScene in orderedScenes {
            let sprites = scriptScene.getSprites()
            
            for sprite in sprites {
                let spriteCommands = convertSpriteToOSB(sprite: sprite)
                osbContent += spriteCommands
            }
        }
        
        // Escribir el contenido al archivo
        do {
            try osbContent.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
            let pasteboard = NSPasteboard.general
                    
            // Limpiar el contenido actual del portapapeles
            pasteboard.clearContents()
            
            // Copiar el nuevo contenido
            let result = pasteboard.setString(osbContent, forType: .string)
            
            if result {
                print("✅ Contenido OSB copiado al portapapeles")
            } else {
                print("❌ Error al copiar contenido OSB al portapapeles")
            }
            
            print("✅ Archivo .osb generado exitosamente en: \(outputPath)")
            return true
        } catch {
            print("❌ Error al escribir archivo .osb: \(error)")
            return false
        }
    }
    
    // Convierte un sprite y sus animaciones a comandos .osb
    private func convertSpriteToOSB(sprite: Sprite) -> String {
        // Determinar layer (capa)
        let layer = "Foreground"
        
        // Determinar origin (origen)
        let origin = sprite.spriteOrigin.name
        let filepath = sprite.path
        // Posición inicial
        let initialPosition = sprite.position
        let x = initialPosition.x + 320 // Convertir de coordenadas SpriteKit a osu!
        let y = 240 - initialPosition.y // Convertir de coordenadas SpriteKit a osu!
        // Comando base del sprite
        var commands = "Sprite,\(layer),\(origin),\"\(filepath)\",\(CGFloat(x)),\(CGFloat(y))\n"
        
        // Añadir comandos de animación basados en los tweens del sprite
        commands += convertTweens(sprite)
        commands += convertColorTweens(sprite)
        
        return commands
    }
    
    private func convertTweens(_ sprite: Sprite) -> String {
        var commands = ""
        
        for tween in sprite.getFadeTweens() {
            commands += " F,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),\(tween.startValue),\(tween.endValue)\n"
        }
        
        for tween in sprite.getScaleTweens() {
            commands += " S,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),\(tween.startValue),\(tween.endValue)\n"
        }
        
        for tween in sprite.getRotateTweens() {
            commands += " R,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),\(tween.startValue),\(tween.endValue)\n"
        }
        
        for tween in sprite.getMoveYTweens() {
            let startY = tween.startValue as! CGFloat
            let endY = tween.endValue as! CGFloat
            commands += " MY,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),\(240 - startY),\(240 - endY)\n"
        }
        
        for tween in sprite.getMoveXTweens() {
            let startX = tween.startValue as! CGFloat
            let endX = tween.endValue as! CGFloat
            commands += " MX,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),\(startX + 320),\(endX + 320)\n"
        }
        
        let blendModeInfo = sprite.getBlendModeInfo()
           
           // Procesar keyframes (cambios instantáneos)
           for keyframe in blendModeInfo.keyframes {
               commands += " P,0,\(keyframe.time),\(keyframe.time),A\n"
           }
           
           // Procesar tweens (transiciones)
           for tween in blendModeInfo.tweens {
               commands += " P,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),A\n"
           }
        
        for tween in sprite.getMoveTweens() {
            let startPoint = tween.startValue as! CGPoint
            let endPoint = tween.endValue as! CGPoint
            
            // Convertir de coordenadas SpriteKit a osu!
            let startX = startPoint.x + 320
            let startY = 240 - startPoint.y
            let endX = endPoint.x + 320
            let endY = 240 - endPoint.y
            
            commands += " M,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),\(CGFloat(startX)),\(CGFloat(startY)),\(CGFloat(endX)),\(CGFloat(endY))\n"
        }
        
        for tween in sprite.getScaleVecTweens() {
            let startPoint = tween.startValue as! CGPoint
            let endPoint = tween.endValue as! CGPoint
            
            commands += " V,\(tween.easing.index ?? 0),\(tween.startTime),\(tween.endTime),\(CGFloat(startPoint.x)),\(CGFloat(startPoint.y)),\(CGFloat(endPoint.x)),\(CGFloat(endPoint.y))\n"
        }
        
        return commands
    }
    
    private func convertColorTweens(_ sprite: Sprite) -> String {
        var commands = ""
        
        for tween in sprite.getColorTweens() {
            let easing = tween.easing.index ?? 0
            
            // Extraer componentes de color
            let startColor = tween.startValue as! SKColor
            let endColor = tween.endValue as! SKColor
            
            var startR: CGFloat = 0, startG: CGFloat = 0, startB: CGFloat = 0, startA: CGFloat = 0
            var endR: CGFloat = 0, endG: CGFloat = 0, endB: CGFloat = 0, endA: CGFloat = 0
            
            startColor.getRed(&startR, green: &startG, blue: &startB, alpha: &startA)
            endColor.getRed(&endR, green: &endG, blue: &endB, alpha: &endA)
            
            // Convertir a rango 0-255
            let startR255 = Int(startR * 255)
            let startG255 = Int(startG * 255)
            let startB255 = Int(startB * 255)
            let endR255 = Int(endR * 255)
            let endG255 = Int(endG * 255)
            let endB255 = Int(endB * 255)
            
            commands += " C,\(easing),\(tween.startTime),\(tween.endTime),\(startR255),\(startG255),\(startB255),\(endR255),\(endG255),\(endB255)\n"
        }
        
        return commands
    }
}

