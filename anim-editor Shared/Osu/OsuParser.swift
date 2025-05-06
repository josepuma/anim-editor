//
//  OsuParser.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

import SpriteKit

class OsuParser {
    private var filePath: String
    private var spriteManager: SpriteManager
    private var hitcircleTexture: SKTexture
    private var hitcircleOverlayTexture: SKTexture
    private var approachCircleTexture: SKTexture
    private var numberTextures: [SKTexture]
    
    // Datos parseados
    private var hitObjects: [OsuHitObject] = []
    private var timingPoints: [TimingPoint] = []
    private var beatmapInfo: [String: String] = [:]
    private var comboNumber: Int = 1
    
    private var comboColors: [SKColor] = []
    private var currentComboNumber: Int = 0
    private var currentComboColorIndex: Int = 0
    
    init(filePath: String, spriteManager: SpriteManager, hitcircleTexture: SKTexture, hitcircleOverlayTexture: SKTexture, approachCircleTexture: SKTexture, numberTextures: [SKTexture]) {
        self.filePath = filePath
        self.spriteManager = spriteManager
        self.hitcircleTexture = hitcircleTexture
        self.hitcircleOverlayTexture = hitcircleOverlayTexture
        self.approachCircleTexture = approachCircleTexture
        self.numberTextures = numberTextures
    }
    
    func parse() {
        do {
            let fileContent = try String(contentsOfFile: filePath, encoding: .utf8)
            let lines = fileContent.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n")
            
            var currentSection: String = ""
            var comboColors: [SKColor] = []
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Saltar líneas vacías y comentarios
                if trimmedLine.isEmpty || trimmedLine.starts(with: "//") {
                    continue
                }
                
                // Verificar encabezados de sección
                if trimmedLine.starts(with: "[") && trimmedLine.hasSuffix("]") {
                    currentSection = String(trimmedLine.dropFirst().dropLast())
                    continue
                }
                
                // Procesar contenido según la sección actual
                switch currentSection {
                case "Colours":
                    if trimmedLine.contains(":") {
                        let parts = trimmedLine.split(separator: ":", maxSplits: 1)
                        if parts.count == 2 {
                            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                            
                            // Parsear colores de combo (Combo1: 255,192,0)
                            if key.starts(with: "Combo") {
                                if let color = parseColor(from: value) {
                                    comboColors.append(color)
                                }
                            }
                            
                            beatmapInfo[key] = value
                        }
                    }
                    
                case "General", "Editor", "Metadata", "Difficulty", "Events":
                    if trimmedLine.contains(":") {
                        let parts = trimmedLine.split(separator: ":", maxSplits: 1)
                        if parts.count == 2 {
                            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                            beatmapInfo[key] = value
                        }
                    }
                    
                case "TimingPoints":
                    if !trimmedLine.contains(":") && trimmedLine.contains(",") {
                        let timingPoint = TimingPoint(fromString: trimmedLine)
                        timingPoints.append(timingPoint)
                    }
                    
                case "HitObjects":
                    parseHitObject(line: String(trimmedLine))
                    
                default:
                    // Sección desconocida, ignorar
                    break
                }
            }
            
            // Si no se encontraron colores, usar colores predeterminados
            if comboColors.isEmpty {
                comboColors = [
                    SKColor(red: 255/255, green: 192/255, blue: 0/255, alpha: 1),   // Amarillo
                    SKColor(red: 0/255, green: 202/255, blue: 0/255, alpha: 1),     // Verde
                    SKColor(red: 18/255, green: 124/255, blue: 255/255, alpha: 1),  // Azul
                    SKColor(red: 242/255, green: 24/255, blue: 57/255, alpha: 1)    // Rojo
                ]
            }
            
            // Guardar los colores para su uso posterior
            self.comboColors = comboColors
            
            print("Parseados \(hitObjects.count) objetos")
            
        } catch {
            print("Error leyendo archivo .osu: \(error)")
        }
    }

    // Método auxiliar para parsear un color en formato R,G,B
    private func parseColor(from string: String) -> SKColor? {
        let components = string.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        guard components.count >= 3,
              let r = Int(components[0]),
              let g = Int(components[1]),
              let b = Int(components[2]) else {
            return nil
        }
        
        return SKColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1.0)
    }
    
    private func parseHitObject(line: String) {
        let parts = line.split(separator: ",").map { String($0) }
        
        guard parts.count >= 5 else {
            print("Línea de objeto inválida: \(line)")
            return
        }
        
        let x = CGFloat(Double(parts[0]) ?? 0)
        let y = CGFloat(Double(parts[1]) ?? 0)
        let time = Int(parts[2]) ?? 0
        let typeValue = Int(parts[3]) ?? 0
        let hitsoundType = Int(parts[4]) ?? 0
        
        let position = OsuPoint(x: x, y: y)
        let types = OsuHitObjectType.getType(from: typeValue)
        let newCombo = (typeValue & 4) != 0
        let comboColorOffset = (typeValue & 0x70) >> 4
        
        if types.contains(.circle) {
            let circle = OsuCircle(position: position, time: time, type: .circle, newCombo: newCombo, comboColorOffset: comboColorOffset, hitsoundType: hitsoundType)
            
            // Parsear extras si está disponible
            if parts.count > 5 {
                circle.extras["extras"] = parts[5]
                if let lastPart = parts.last, lastPart.contains(":") {
                    circle.hitSample = HitSoundManager.HitSampleInfo(fromString: lastPart)
                }
            }
            
            hitObjects.append(circle)
        }
        
        if types.contains(.slider) {
            guard parts.count >= 8 else {
                print("Línea de slider inválida: \(line)")
                return
            }
            
            // Parsear datos de la curva
            let curveData = parts[5].split(separator: "|")
            let curveType = SliderCurveType.fromString(String(curveData[0]))
            
            var curvePoints: [OsuPoint] = []
            for i in 1..<curveData.count {
                let pointStr = String(curveData[i])
                let pointParts = pointStr.split(separator: ":").map { String($0) }
                
                if pointParts.count == 2 {
                    let pointX = CGFloat(Double(pointParts[0]) ?? 0)
                    let pointY = CGFloat(Double(pointParts[1]) ?? 0)
                    curvePoints.append(OsuPoint(x: pointX, y: pointY))
                }
            }
            
            let slides = Int(parts[6]) ?? 1
            let length = Double(parts[7]) ?? 0
            
            var edgeSounds: [Int] = []
            var edgeSets: [String] = []
            
            // Parsear sonidos y sets de bordes si están disponibles
            if parts.count > 8 {
                edgeSounds = parts[8].split(separator: "|").compactMap { Int($0) }
            }
            
            if parts.count > 9 {
                edgeSets = parts[9].split(separator: "|").map { String($0) }
            }
        
            
            let slider = OsuSlider(
                position: position,
                time: time,
                type: .slider,
                newCombo: newCombo,
                comboColorOffset: comboColorOffset,
                hitsoundType: hitsoundType,
                curveType: curveType,
                curvePoints: curvePoints,
                slides: slides,
                length: length,
                edgeSounds: edgeSounds,
                edgeSets: edgeSets
            )
            
            if parts.count > 10 { // El último campo después de edgeSets
                slider.extras["extras"] = parts[10]
                
                // Parsear hitSample si está disponible (el último campo)
                if let lastPart = parts.last, lastPart.contains(":") {
                    slider.hitSample = HitSoundManager.HitSampleInfo(fromString: lastPart)
                }
            }
            
            hitObjects.append(slider)
        }
    }
    
    func findActiveTimingPoint(at time: Int) -> TimingPoint? {
        // Timing points están ordenados por tiempo
        var lastUninheritedPoint: TimingPoint? = nil
        var closestPoint: TimingPoint? = nil
        
        for point in timingPoints {
            if point.time <= time {
                closestPoint = point
                
                if point.uninherited {
                    lastUninheritedPoint = point
                }
            } else {
                break // Los timing points posteriores ya no aplican
            }
        }
        
        // Si el punto más cercano es heredado, necesitamos combinarlo con el último punto no heredado
        if let closestPoint = closestPoint, !closestPoint.uninherited, let parent = lastUninheritedPoint {
            var combined = closestPoint
            // Los puntos heredados usan el beatLength del padre
            combined.beatLength = parent.beatLength
            return combined
        }
        
        return closestPoint
    }
    
    func createSprites() {
        comboNumber = 1
        currentComboColorIndex = 0
        for hitObject in hitObjects {
            if hitObject.newCombo {
                comboNumber = 1
                currentComboNumber = 1
                currentComboColorIndex = (currentComboColorIndex + 1 + hitObject.comboColorOffset) % comboColors.count
            }
            // Obtener el color actual del combo
            let comboColor = comboColors[currentComboColorIndex]
            
            if let circle = hitObject as? OsuCircle {
                // Crear el sprite completo del círculo (con overlay y número)
                createFullCircleSprite(circle, comboNumber: currentComboNumber, comboColor: comboColor)
                
                // Incrementar el número de combo para el siguiente objeto
                currentComboNumber += 1
            } else if let slider = hitObject as? OsuSlider {
                // Primero crear el sprite del path del slider con zPosition menor
                let pathSprite = slider.createSliderPathSprite()
                pathSprite.zPosition = 1
                spriteManager.addSprite(pathSprite)
                
                // Luego crear el sprite completo del círculo inicial con zPosition mayor
                createFullCircleSprite(slider, comboNumber: currentComboNumber, comboColor: comboColor)
                
                // Incrementar el número de combo para el siguiente objeto
                currentComboNumber += 1
            }
        }
    }
    
    private func createFullCircleSprite(_ hitObject: OsuHitObject, comboNumber: Int, comboColor: SKColor) {
            let position = hitObject.position.toSpriteKitPosition(width: 640, height: 480)
        
            let endTime: Int
            if let slider = hitObject as? OsuSlider {
                // Para sliders, el tiempo de finalización es el tiempo inicial + la duración
                let sliderDuration = 500 * slider.slides // milisegundos por repetición
                endTime = hitObject.time + sliderDuration
            } else {
                // Para círculos normales, el tiempo de finalización es el tiempo de hit
                endTime = hitObject.time
            }
            
            // 1. Crear el sprite base del círculo
            let circleSprite = hitObject.createSprite(circleTexture: hitcircleTexture, approachTexture: approachCircleTexture)
            circleSprite.addColorTween(startTime: hitObject.time, endTime: hitObject.time, startValue: comboColor, endValue: comboColor)
            circleSprite.zPosition = 2
            spriteManager.addSprite(circleSprite)
            
            // 2. Crear el sprite del overlay
            let overlaySprite = Sprite(texture: hitcircleOverlayTexture)
            overlaySprite.setInitialPosition(position: position)
            overlaySprite.zPosition = 3
            
            // Animaciones para el overlay (igual que las del círculo base)
            overlaySprite.addFadeTween(easing: .sineOut,
                                     startTime: hitObject.time - 800,
                                     endTime: hitObject.time - 600,
                                     startValue: 0,
                                     endValue: 1)
            
            overlaySprite.addScaleTween(easing: .sineOut,
                                      startTime: hitObject.time - 800,
                                      endTime: hitObject.time - 600,
                                      startValue: 0.1,
                                        endValue: 0.65)
            
            overlaySprite.addFadeTween(easing: .linear,
                                     startTime: hitObject.time - 600,
                                     endTime: endTime,
                                     startValue: 1,
                                     endValue: 1)
            
            overlaySprite.addFadeTween(easing: .sineIn,
                                     startTime: endTime,
                                     endTime: endTime + 200,
                                     startValue: 1,
                                     endValue: 0)
            
            spriteManager.addSprite(overlaySprite)
            
            // 3. Crear el sprite del número de combo
            // Asegurarse de que el número esté dentro del rango de texturas disponibles
            let safeComboNumber = max(comboNumber, 1)

            
            if comboNumber < 10 {
                // Números de un solo dígito
                let comboIndex = safeComboNumber % 10
                let numberTexture = numberTextures[comboIndex]
                
                let numberSprite = Sprite(texture: numberTexture)
                numberSprite.setInitialPosition(position: position)
                numberSprite.addFadeTween(easing: .sineOut,
                                            startTime: hitObject.time - 800,
                                            endTime: hitObject.time - 600,
                                            startValue: 0,
                                            endValue: 1)
                
                numberSprite.addScaleTween(easing: .sineOut,
                                         startTime: hitObject.time - 800,
                                         endTime: hitObject.time - 600,
                                         startValue: 0.1,
                                           endValue: 0.65)
                
                numberSprite.addFadeTween(easing: .linear,
                                        startTime: hitObject.time - 600,
                                        endTime: endTime,
                                        startValue: 1,
                                        endValue: 1)
                
                numberSprite.addFadeTween(easing: .sineIn,
                                        startTime: endTime,
                                        endTime: endTime + 200,
                                        startValue: 1,
                                        endValue: 0)
                
                spriteManager.addSprite(numberSprite)
            } else {
                // Números de dos dígitos (10-99)
                let decenas = (safeComboNumber / 10) % 10  // Esto dará un valor entre 0-9
                let unidades = safeComboNumber % 10
                
                let decenasIndex = min(decenas, numberTextures.count - 1)
                let unidadesIndex = min(unidades, numberTextures.count - 1)
                
                // Sprite para las decenas (ligeramente desplazado a la izquierda)
                let decenasTexture = numberTextures[decenasIndex]
                        
                let decenasSprite = Sprite(texture: decenasTexture)
                let offsetX: CGFloat = -10  // Desplazamiento a la izquierda
                decenasSprite.setInitialPosition(position: CGPoint(x: position.x + offsetX, y: position.y))
                decenasSprite.zPosition = 4
                
                // Animaciones para el sprite de decenas
                // ... (las mismas animaciones que para números de un dígito)
                
                spriteManager.addSprite(decenasSprite)
                
                // Sprite para las unidades (ligeramente desplazado a la derecha)
                let unidadesTexture = numberTextures[unidadesIndex]
                let unidadesSprite = Sprite(texture: unidadesTexture)
                let offsetY: CGFloat = 10  // Desplazamiento a la derecha
                unidadesSprite.setInitialPosition(position: CGPoint(x: position.x + offsetY, y: position.y))
                unidadesSprite.zPosition = 4
                
                // Animaciones para el sprite de unidades
                // ... (las mismas animaciones que para números de un dígito)
                
                spriteManager.addSprite(unidadesSprite)
            }
            
            /*let numberSprite = Sprite(texture: numberTexture)
            numberSprite.setInitialPosition(position: position)
            numberSprite.zPosition = 4*/
            
            // Animaciones para el número (igual que las del círculo base)
            /*numberSprite.addFadeTween(easing: .sineOut,
                                    startTime: hitObject.time - 800,
                                    endTime: hitObject.time - 600,
                                    startValue: 0,
                                    endValue: 1)
            
            numberSprite.addScaleTween(easing: .sineOut,
                                     startTime: hitObject.time - 800,
                                     endTime: hitObject.time - 600,
                                     startValue: 0.1,
                                       endValue: 0.65)
            
            numberSprite.addFadeTween(easing: .linear,
                                    startTime: hitObject.time - 600,
                                    endTime: endTime,
                                    startValue: 1,
                                    endValue: 1)
            
            numberSprite.addFadeTween(easing: .sineIn,
                                    startTime: endTime,
                                    endTime: endTime + 200,
                                    startValue: 1,
                                    endValue: 0)
            
            spriteManager.addSprite(numberSprite)*/
            
            // 4. Crear el approach circle con la zPosition más alta
            let approachSprite = OsuCircle(
                position: hitObject.position,
                time: hitObject.time,
                type: .circle,
                newCombo: hitObject.newCombo,
                comboColorOffset: hitObject.comboColorOffset,
                hitsoundType: hitObject.hitsoundType
            ).createApproachSprite(approachTexture: approachCircleTexture)
            approachSprite.addColorTween(startTime: hitObject.time, endTime: hitObject.time, startValue: comboColor, endValue: comboColor)
            approachSprite.zPosition = 5
            spriteManager.addSprite(approachSprite)
        }
    
    func getHitObjects() -> [OsuHitObject] {
        return hitObjects
    }
    
    func getBeatmapInfo() -> [String: String] {
        return beatmapInfo
    }
}
