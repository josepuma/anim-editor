//
//  ParticleAPIExport.swift
//  anim-editor
//
//  Created by José Puma on 17-04-25.
//

import JavaScriptCore
import SpriteKit

struct TextStyleConfig {
    // Propiedades básicas
    var text: String
    var fontName: String
    var fontSize: CGFloat
    var color: [Double] // [R, G, B, A]
    var spacing: CGFloat
    
    // Efectos de texto
    var shadow: Bool = false
    var shadowColor: [Double] = [0, 0, 0, 0.5] // [R, G, B, A]
    var shadowOffset: [CGFloat] = [2, 2] // [x, y]
    var shadowBlur: CGFloat = 3
    
    // Efectos de borde
    var stroke: Bool = false
    var strokeColor: [Double] = [0, 0, 0, 1]
    var strokeWidth: CGFloat = 1
    
    // Efectos adicionales
    var blur: Bool = false
    var blurRadius: CGFloat = 2
    var glow: Bool = false
    var glowColor: [Double] = [1, 1, 1, 0.8]
    var glowRadius: CGFloat = 4
    
    // Opciones de diseño
    var align: String = "center" // "left", "center", "right"
    var lineHeight: CGFloat = 1.2 // multiplicador para espaciado vertical
    var letterSpacing: CGFloat = 0 // espaciado adicional entre letras
    
    // Opciones de posicionamiento
    var baselineAlignment: Bool = true
}

// 1. Definir un protocolo que extienda JSExport con todos los métodos que necesitamos
@objc protocol ParticleAPIExport: JSExport {
    func createSprite(_ texturePath: String, _ origin: String) -> JSValue
    func clearEffects()
    func getCurrentTime() -> Int
    func random(_ min: Double, _ max: Double) -> Double
    func randomInt(_ min: Int, _ max: Int) -> Int
    func log(_ text: String) -> Void
    func createText(_ config: [String: Any]) -> JSValue
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
    
    func log(_ text: String){
        print(text)
    }
    
    func getEasingFromString(_ string: String) -> Easing {
       // Si tienes acceso al método del intérprete, úsalo
       if let easing = interpreter?.getEasingFromString(string) {
           return easing
       }
    return .linear
   }
    
    func createText(_ config: [String: Any]) -> JSValue {
        guard let context = JSContext.current(),
              let _ = particleManager else {
            print("❌ ERROR: No se pudo crear texto estilizado")
            return JSValue(nullIn: JSContext.current())
        }

        // Extraer configuración básica
        let text = config["text"] as? String ?? ""
        let fontName = config["fontName"] as? String ?? "HelveticaNeue"
        let fontSize = CGFloat(config["fontSize"] as? Double ?? 24)
        let colorArray = config["color"] as? [Double] ?? [255, 255, 255, 1]

        // Extraer configuración de color
        let textColor = SKColor(
            red: CGFloat(colorArray[0] / 255.0),
            green: CGFloat(colorArray[1] / 255.0),
            blue: CGFloat(colorArray[2] / 255.0),
            alpha: colorArray.count > 3 ? CGFloat(colorArray[3]) : 1.0
        )

        // Crear array para devolver
        let jsArray = JSValue(newArrayIn: context)

        // Calcular altura fija para todos los caracteres (para consistencia)
        let fixedHeight = fontSize * 1.5
        let baselinePosition = fixedHeight * 0.33

        // Procesar cada carácter
        for (index, char) in text.enumerated() {
            // Crear label con el carácter
            let letterLabel = SKLabelNode(text: String(char))
            letterLabel.fontName = fontName
            letterLabel.fontSize = fontSize
            letterLabel.fontColor = textColor
            letterLabel.verticalAlignmentMode = .baseline
            letterLabel.horizontalAlignmentMode = .center

            // Calcular un ancho inicial estimado para la escena
            let initialSceneWidth: CGFloat = (char == " ") ? fontSize * 0.5 : letterLabel.calculateAccumulatedFrame().width + 10

            let scene = SKScene(size: CGSize(width: initialSceneWidth, height: fixedHeight))
            scene.backgroundColor = .clear
            letterLabel.position = CGPoint(x: scene.size.width / 2, y: baselinePosition)

            // Aplicar efectos a la etiqueta
            let _ = applyTextEffects(to: letterLabel, in: scene, config: config)

            // Añadir la etiqueta a la escena después de aplicar efectos
            scene.addChild(letterLabel)

            // Calcular el frame *después* de aplicar los efectos
            let contentFrameWithEffects = scene.calculateAccumulatedFrame()

            // Ajustar el ancho de la escena al contenido con efectos + un margen adicional
            let adjustedWidth = max(contentFrameWithEffects.width + 10, 1)

            // Ajustar el tamaño de la escena al contenido real con efectos y margen
            scene.size = CGSize(width: adjustedWidth, height: fixedHeight)

            // Re-centrar la etiqueta dentro de la escena ajustada
            letterLabel.position = CGPoint(x: adjustedWidth / 2, y: baselinePosition)

            // Crear vista para renderizar
            let view = SKView(frame: CGRect(x: 0, y: 0, width: adjustedWidth, height: fixedHeight + 5))

            // Generar textura
            let texture = view.texture(from: scene) ?? SKTexture()

            // Crear sprite con la textura
            let sprite = Sprite(texture: texture)

            // Añadir a script
            if let scriptId = interpreter?.currentScriptId {
                interpreter?.addSpriteToScript(scriptId: scriptId, sprite: sprite)
            }

            // Crear objeto JS para este sprite
            let spriteObj = JSValue(newObjectIn: context)

            // Añadir propiedades de dimensión
            spriteObj?.setValue(texture.size().width, forProperty: "width")
            spriteObj?.setValue(fixedHeight, forProperty: "height")

            // Añadir métodos al objeto sprite JS
            addSpriteMethods(to: spriteObj, for: sprite)

            // Añadir al array
            jsArray?.setObject(spriteObj, atIndexedSubscript: Int(UInt32(index)))
        }

        return jsArray!
    }
    

    /// Función para aplicar efectos de texto

    private func applyTextEffects(to label: SKLabelNode, in scene: SKScene, config: [String: Any]) -> CGRect {
        // Propiedades originales para referencia
        let originalText = label.text ?? ""
        let originalFontName = label.fontName
        let originalFontSize = label.fontSize
        let originalPosition = label.position

        var minX: CGFloat = originalPosition.x
        var maxX: CGFloat = originalPosition.x
        var minY: CGFloat = originalPosition.y
        var maxY: CGFloat = originalPosition.y
        
        // ------ BLUR ------
        if config["blur"] as? Bool == true {
            // Extraer configuración de blur
            let blurRadius = CGFloat(config["blurRadius"] as? Double ?? 2.0)
            
            // En lugar de aplicar el blur al label directamente, creamos un SKEffectNode
            // y lo añadimos a la escena en la misma posición que el label existente
            let effectNode = SKEffectNode()
            effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": blurRadius])
            effectNode.shouldRasterize = true
            effectNode.position = originalPosition
            
            // Crear una nueva copia del texto para el blur
            let blurText = SKLabelNode(text: originalText)
            blurText.fontName = originalFontName
            blurText.fontSize = originalFontSize
            blurText.fontColor = label.fontColor
            blurText.verticalAlignmentMode = label.verticalAlignmentMode
            blurText.horizontalAlignmentMode = label.horizontalAlignmentMode
            
            // Añadir la copia de texto al nodo de efecto
            effectNode.addChild(blurText)
            
            // Añadir el nodo de efecto a la escena
            scene.addChild(effectNode)
            
            // Ocultar el label original si queremos solo mostrar la versión con blur
            label.isHidden = true
            
            // Ajustar los límites para el blur
            let blurredFrame = effectNode.calculateAccumulatedFrame()
            minX = min(minX, blurredFrame.minX)
            maxX = max(maxX, blurredFrame.maxX)
            minY = min(minY, blurredFrame.minY)
            maxY = max(maxY, blurredFrame.maxY)
        }

        // ------ SOMBRA ------
        if config["shadow"] as? Bool == true {
            // Extraer configuración de sombra
            let shadowColorArray = config["shadowColor"] as? [Double] ?? [0, 0, 0, 0.5]
            let shadowColor = SKColor(
                red: CGFloat(shadowColorArray[0] / 255.0),
                green: CGFloat(shadowColorArray[1] / 255.0),
                blue: CGFloat(shadowColorArray[2] / 255.0),
                alpha: shadowColorArray.count > 3 ? CGFloat(shadowColorArray[3]) : 0.5
            )

            let shadowOffsetArray = config["shadowOffset"] as? [CGFloat] ?? [2, 2]
            let shadowOffset = CGPoint(
                x: shadowOffsetArray.count > 0 ? shadowOffsetArray[0] : 2,
                y: shadowOffsetArray.count > 1 ? shadowOffsetArray[1] : 2
            )

            // Crear un nodo de sombra
            let shadowNode = SKLabelNode(text: originalText)
            shadowNode.fontName = originalFontName
            shadowNode.fontSize = originalFontSize
            shadowNode.fontColor = shadowColor
            shadowNode.position = CGPoint(
                x: originalPosition.x + shadowOffset.x,
                y: originalPosition.y - shadowOffset.y
            )
            shadowNode.verticalAlignmentMode = label.verticalAlignmentMode
            shadowNode.horizontalAlignmentMode = label.horizontalAlignmentMode

            // Actualizar la extensión
            minX = min(minX, shadowNode.frame.minX)
            maxX = max(maxX, shadowNode.frame.maxX)
            minY = min(minY, shadowNode.frame.minY)
            maxY = max(maxY, shadowNode.frame.maxY)

            // Añadir blur a la sombra si está configurado
            if let shadowBlur = config["shadowBlur"] as? CGFloat, shadowBlur > 0 {
                let effectNode = SKEffectNode()
                effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": shadowBlur])
                effectNode.shouldRasterize = true
                effectNode.position = shadowNode.position

                // Crear un nuevo nodo de texto para la sombra
                let blurText = SKLabelNode(text: originalText)
                blurText.fontName = originalFontName
                blurText.fontSize = originalFontSize
                blurText.fontColor = shadowColor
                blurText.verticalAlignmentMode = label.verticalAlignmentMode
                blurText.horizontalAlignmentMode = label.horizontalAlignmentMode

                // Actualizar la extensión (el blur puede extender aún más)
                let blurredFrame = blurText.calculateAccumulatedFrame().offsetBy(dx: effectNode.position.x, dy: effectNode.position.y)
                minX = min(minX, blurredFrame.minX)
                maxX = max(maxX, blurredFrame.maxX)
                minY = min(minY, blurredFrame.minY)
                maxY = max(maxY, blurredFrame.maxY)

                // Añadir a la jerarquía de nodos correcta
                effectNode.addChild(blurText)
                scene.addChild(effectNode)
            } else {
                // Si no hay blur, añadir directamente
                scene.addChild(shadowNode)
            }
        }

        // ------ BORDE / STROKE ------
        if config["stroke"] as? Bool == true {
            // Extraer configuración de borde
            let strokeColorArray = config["strokeColor"] as? [Double] ?? [0, 0, 0, 1]
            let strokeColor = SKColor(
                red: CGFloat(strokeColorArray[0] / 255.0),
                green: CGFloat(strokeColorArray[1] / 255.0),
                blue: CGFloat(strokeColorArray[2] / 255.0),
                alpha: strokeColorArray.count > 3 ? CGFloat(strokeColorArray[3]) : 1.0
            )

            let strokeWidth = CGFloat(config["strokeWidth"] as? Double ?? 1)

            // Para crear un borde, vamos a crear múltiples copias del texto en diferentes posiciones
            let positions: [CGPoint] = [
                CGPoint(x: -strokeWidth, y: 0),
                CGPoint(x: strokeWidth, y: 0),
                CGPoint(x: 0, y: -strokeWidth),
                CGPoint(x: 0, y: strokeWidth),
                CGPoint(x: -strokeWidth, y: -strokeWidth),
                CGPoint(x: strokeWidth, y: -strokeWidth),
                CGPoint(x: -strokeWidth, y: strokeWidth),
                CGPoint(x: strokeWidth, y: strokeWidth)
            ]

            // Crear los nodos de borde
            for position in positions {
                let strokeNode = SKLabelNode(text: originalText)
                strokeNode.fontName = originalFontName
                strokeNode.fontSize = originalFontSize
                strokeNode.fontColor = strokeColor
                strokeNode.position = CGPoint(
                    x: originalPosition.x + position.x,
                    y: originalPosition.y + position.y
                )
                strokeNode.verticalAlignmentMode = label.verticalAlignmentMode
                strokeNode.horizontalAlignmentMode = label.horizontalAlignmentMode

                // Actualizar la extensión
                minX = min(minX, strokeNode.frame.minX)
                maxX = max(maxX, strokeNode.frame.maxX)
                minY = min(minY, strokeNode.frame.minY)
                maxY = max(maxY, strokeNode.frame.maxY)

                // Añadir a la escena
                scene.addChild(strokeNode)
            }
        }

        // ------ GLOW / BRILLO ------
        if config["glow"] as? Bool == true {
            // Extraer configuración de brillo
            let glowColorArray = config["glowColor"] as? [Double] ?? [255, 255, 255, 0.8]
            let glowColor = SKColor(
                red: CGFloat(glowColorArray[0] / 255.0),
                green: CGFloat(glowColorArray[1] / 255.0),
                blue: CGFloat(glowColorArray[2] / 255.0),
                alpha: glowColorArray.count > 3 ? CGFloat(glowColorArray[3]) : 0.8
            )

            let glowRadius = CGFloat(config["glowRadius"] as? Double ?? 4)

            // Crear capas de glow con diferentes intensidades
            for i in 1...3 {
                let intensity = CGFloat(i) / 3.0

                // Crear nodo de efecto para el glow
                let effectNode = SKEffectNode()
                effectNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": glowRadius * intensity])
                effectNode.shouldRasterize = true
                effectNode.position = originalPosition

                // Crear texto para el glow
                let glowTextNode = SKLabelNode(text: originalText)
                glowTextNode.fontName = originalFontName
                glowTextNode.fontSize = originalFontSize * (1 + 0.1 * intensity)

                // Color con transparencia variable
                var glowRed: CGFloat = 0
                var glowGreen: CGFloat = 0
                var glowBlue: CGFloat = 0
                var glowAlpha: CGFloat = 0
                glowColor.getRed(&glowRed, green: &glowGreen, blue: &glowBlue, alpha: &glowAlpha)

                glowTextNode.fontColor = SKColor(
                    red: glowRed,
                    green: glowGreen,
                    blue: glowBlue,
                    alpha: glowAlpha * (1 - 0.3 * intensity)
                )

                glowTextNode.verticalAlignmentMode = label.verticalAlignmentMode
                glowTextNode.horizontalAlignmentMode = label.horizontalAlignmentMode

                // Actualizar la extensión (el blur del glow también extiende)
                let glowFrame = glowTextNode.calculateAccumulatedFrame().offsetBy(dx: effectNode.position.x, dy: effectNode.position.y)
                minX = min(minX, glowFrame.minX)
                maxX = max(maxX, glowFrame.maxX)
                minY = min(minY, glowFrame.minY)
                maxY = max(maxY, glowFrame.maxY)

                // Añadir a la jerarquía
                effectNode.addChild(glowTextNode)
                scene.addChild(effectNode)
            }
        }

        // Devolver la extensión total de los efectos
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    // Método para crear un JSValue que represente al sprite
    private func createJSValueForSprite(_ sprite: Sprite) -> JSValue {
        guard let context = JSContext.current() else {
            return JSValue(nullIn: JSContext.current())
        }
        
        // Crear objeto JS
        let spriteObj = JSValue(newObjectIn: context)
        
        // Registrar métodos para el sprite - los mismos que ya tienes en tu API
        // Por ejemplo, addMoveXTween:
        let addMoveXTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addMoveXTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        spriteObj?.setValue(addMoveXTween, forProperty: "addMoveXTween")
        
        // Añade el resto de métodos que ya tienes implementados para los sprites normales
        // ...
        
        return spriteObj!
    }
    
    func createSprite(_ texturePath: String, _ origin: String) -> JSValue {
        guard let context = JSContext.current(),
              let particleManager = particleManager,
              let texture = particleManager.textureLoader.getTexture(named: texturePath) else {
            print("❌ ERROR: No se pudo crear sprite con textura: \(texturePath)")
            return JSValue(nullIn: JSContext.current())
        }
        let originSprite = Origin(rawValue: origin) ?? .centre
        // Crear sprite
        let sprite = Sprite(texture: texture, origin: originSprite, spritePath: texturePath)
        
        // Añadir a lista de sprites del script
        if let scriptId = interpreter?.currentScriptId {
            interpreter?.addSpriteToScript(scriptId: scriptId, sprite: sprite)
        }
        
        // Crear objeto JS para el sprite
        let spriteObj = JSValue(newObjectIn: context)
        
        
        addSpriteMethods(to: spriteObj, for: sprite)
        
        // Añadir sprite al manager
        //particleManager.spriteManager.addSprite(sprite)
        
        return spriteObj!
    }
    
    func clearEffects() {
        guard let interpreter = interpreter,
              let scriptId = interpreter.currentScriptId else {
            return
        }
        
        // Limpiar los sprites de la escena actual
        interpreter.clearScriptsSprites(scriptId)
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
    
    // Función auxiliar para añadir métodos a un objeto sprite JS
    private func addSpriteMethods(to jsObject: JSValue?, for sprite: Sprite) {
        // Método MoveX
        let addMoveXTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addMoveXTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        jsObject?.setValue(addMoveXTween, forProperty: "addMoveXTween")
        
        // Método MoveY
        let addMoveYTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addMoveYTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        jsObject?.setValue(addMoveYTween, forProperty: "addMoveYTween")
        
        let addScaleVecTween: @convention(block) (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startX, startY, endX, endY, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addScaleVecTween(easing: easing, startTime: startTime, endTime: endTime,
                              startValue: CGPoint(x: startX, y: startY),
                              endValue: CGPoint(x: endX, y: endY))
        }
        jsObject?.setValue(addScaleVecTween, forProperty: "addScaleVecTween")
        
        let addColorTween: @convention(block) (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startX, startY, startZ, endX, endY, endZ, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            let startColor = SKColor(red: startX / 255, green: startY / 255, blue: startZ / 255, alpha: 1)
            let endColor = SKColor(red: endX / 255, green: endY / 255, blue: endZ / 255, alpha: 1)
            sprite.addColorTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startColor, endValue: endColor)
        }
        jsObject?.setValue(addColorTween, forProperty: "addColorTween")
        
        
        // Método Fade
        let addFadeTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addFadeTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        jsObject?.setValue(addFadeTween, forProperty: "addFadeTween")
        
        // Método Scale
        let addScaleTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addScaleTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        jsObject?.setValue(addScaleTween, forProperty: "addScaleTween")
        
        // Método Rotate
        let addRotateTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startValue, endValue, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addRotateTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        }
        jsObject?.setValue(addRotateTween, forProperty: "addRotateTween")
        
        // Método Move
        let addMoveTween: @convention(block) (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat, String) -> Void = { [weak self] (startTime, endTime, startX, startY, endX, endY, easingStr) in
            let easing = self?.getEasingFromString(easingStr) ?? .linear
            sprite.addMoveTween(easing: easing, startTime: startTime, endTime: endTime,
                              startValue: CGPoint(x: startX, y: startY),
                              endValue: CGPoint(x: endX, y: endY))
        }
        jsObject?.setValue(addMoveTween, forProperty: "addMoveTween")
        
        // Método BlendMode
        let addBlendMode: @convention(block) (Int, Int) -> Void = { (startTime, endTime) in
            sprite.addBlendModeTween(startTime: startTime, endTime: endTime)
        }
        jsObject?.setValue(addBlendMode, forProperty: "addBlendMode")
        
        // Método SetPosition
        let setPosition: @convention(block) (CGFloat, CGFloat) -> Void = { (x, y) in
            sprite.setInitialPosition(position: CGPoint(x: x, y: y))
        }
        jsObject?.setValue(setPosition, forProperty: "setPosition")
        
        // Métodos Loop
        let startLoop: @convention(block) (Int, Int) -> Void = { (startTime, loopCount) in
            sprite.startLoop(startTime: startTime, loopCount: loopCount)
        }
        jsObject?.setValue(startLoop, forProperty: "startLoop")
        
        let endLoop: @convention(block) () -> Void = {
            sprite.endLoop()
        }
        jsObject?.setValue(endLoop, forProperty: "endLoop")
        
        jsObject?.setValue(sprite.node.size.width, forProperty: "width")
        jsObject?.setValue(sprite.node.size.height, forProperty: "height")
    }

}



extension SKNode {
    func applySKEffect<T: SKEffectNode>(_ effectNode: T, configure: (T) -> Void) {
        // 1. Eliminar este nodo de su padre actual
        let originalParent = self.parent
        let originalPosition = self.position
        let originalZPosition = self.zPosition
        
        self.removeFromParent()
        
        // 2. Configurar el nodo de efecto
        configure(effectNode)
        
        // 3. Añadir este nodo como hijo del nodo de efecto
        effectNode.addChild(self)
        
        // 4. Añadir el nodo de efecto donde estaba este nodo
        effectNode.position = originalPosition
        effectNode.zPosition = originalZPosition
        originalParent?.addChild(effectNode)
    }
}

extension SKColor {
    convenience init(rgbaArray: [Double]) {
        let red = CGFloat(rgbaArray[0] / 255.0)
        let green = CGFloat(rgbaArray[1] / 255.0)
        let blue = CGFloat(rgbaArray[2] / 255.0)
        let alpha = rgbaArray.count > 3 ? CGFloat(rgbaArray[3]) : 1.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
