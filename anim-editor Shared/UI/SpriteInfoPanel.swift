//
//  SpriteInfoPanel.swift
//  anim-editor
//
//  Created by José Puma on 15-04-25.
//

import SpriteKit

class SpriteInfoPanel: VerticalContainer {
    
    private var currentSprite: Sprite?
    private var tweenSections: [String: VerticalContainer] = [:]
    
    //styles
    private var accent = NSColor(red: 202 / 255, green: 217 / 255, blue: 91 / 255, alpha: 1)
    private var backgroundColorAccent = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 0.7)
    private var backgroundColorButton = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
    private var buttonColorText = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)
    
    init() {
        // Mismo estilo que los otros contenedores
        super.init(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: true,
            backgroundColor: NSColor(red: 7 / 255, green: 7 / 255, blue: 13 / 255, alpha: 1),
            cornerRadius: 8
        )
        
        let sectionTitle = Text(text: "Sprite", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0)
        addNode(sectionTitle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateWithSprite(_ sprite: Sprite) {
        // Eliminar todos los nodos hijos excepto el título
        clearNodes()
        
        // Guardar referencia al sprite actual
        currentSprite = sprite

        
        // Añadir secciones para los diferentes tipos de tweens
        addTweenSections(sprite)
        
        // Importante: actualizar el layout después de añadir todo
        updateLayout()
    }
    
    private func clearPanel() {
        // No podemos acceder directamente a childNodes porque es privado
        // En lugar de eso, usamos el método clearNodes() de VerticalContainer
        clearNodes()
        
        tweenSections.removeAll()
    }
    
    private func addTweenSections(_ sprite: Sprite) {
        // Limpiar secciones anteriores
        tweenSections.removeAll()
        
        // Añadir sección para cada tipo de tween si existen tweens de ese tipo
        let moveTweens = sprite.getMoveTweens()
        if !moveTweens.isEmpty {
            let limitedTweens: [TweenInfo] = Array(moveTweens.prefix(5))
            addTweenSection("Position", tweens: limitedTweens)
        }
        
        let scaleTweens = sprite.getScaleTweens()
        if !scaleTweens.isEmpty {
            let limitedTweens: [TweenInfo] = Array(scaleTweens.prefix(5))
            addTweenSection("Scale", tweens: limitedTweens)
        }
        
        let rotateTweens = sprite.getRotateTweens()
        if !rotateTweens.isEmpty {
            addTweenSection("Rotation", tweens: rotateTweens)
        }
        
        let fadeTweens = sprite.getFadeTweens()
        if !fadeTweens.isEmpty {
            let limitedTweens: [TweenInfo] = Array(fadeTweens.prefix(5))
            addTweenSection("Fade", tweens: limitedTweens)
        }
        
        let colorTweens = sprite.getColorTweens()
        if !colorTweens.isEmpty {
            addTweenSection("Color", tweens: colorTweens)
        }
    }
    
    private func addTweenSection(_ title: String, tweens: [TweenInfo]) {
        if tweens.isEmpty {
            return
        }
        
        // Crear título de sección
        let sectionTitle = Text(text: title, fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0)
        addNode(sectionTitle)
        
        // Crear contenedor para este tipo de tween
        let tweenContainer = VerticalContainer(
            spacing: 5,
            padding: CGSize(width: 5, height: 5),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: false,
            backgroundColor: NSColor(red: 28/255, green: 28/255, blue: 42/255, alpha: 1),
            cornerRadius: 5
        )
        
        // Añadir cada tween a la sección
        for (index, tween) in tweens.enumerated() {
            
            let tweenInfo = createTweenInfoDisplay(tween, index: index, type: title)
            tweenContainer.addNode(tweenInfo)
        }
        
        // Guardar referencia al contenedor
        tweenSections[title] = tweenContainer
        
        // Añadir el contenedor al panel
        addNode(tweenContainer)
    }
    
    private func createTweenInfoDisplay(_ tween: TweenInfo, index: Int, type: String) -> HorizontalContainer {
        // Crear contenedor horizontal para este tween
        let tweenDisplay = HorizontalContainer(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .center,
            horizontalAlignment: .left,
            showBackground: false,
            backgroundColor: .clear
        )
        
        tweenDisplay.addNodes([
            Button(text: String(tween.startTime), padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
            Button(text: String(tween.endTime), padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
            Button(text: formatValue(tween.startValue), padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
            Button(text: formatValue(tween.endValue), padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
        ])
        
        // Añadir icono de edición
        /*let editButton = Button(
            text: "",
            shape: .circle,
            size: CGSize(width: 16, height: 16),
            buttonColor: NSColor(red: 202/255, green: 217/255, blue: 91/255, alpha: 1)
        )
        editButton.setIcon(name: "volume", size: 10, color: .black)
        
        // Configurar callback para edición
        editButton.onPress = { [weak self] in
            self?.editTween(type: type, index: index)
        }
        
        // Crear texto con la información del tween
        let infoText = SKLabelNode(text: formatTweenInfo(tween))
        infoText.fontName = "HelveticaNeue"
        infoText.fontSize = 11
        infoText.fontColor = .white
        infoText.horizontalAlignmentMode = .left
        infoText.verticalAlignmentMode = .center
        
        // Añadir a la fila horizontal
        tweenDisplay.addNode(editButton)
        tweenDisplay.addNode(infoText)*/
        
        return tweenDisplay
    }
    
    private func formatTweenInfo(_ tween: TweenInfo) -> String {
        let startValueStr = formatValue(tween.startValue)
        let endValueStr = formatValue(tween.endValue)
        return "t:\(tween.startTime)-\(tween.endTime) \(startValueStr)->\(endValueStr)"
    }
    
    private func editTween(type: String, index: Int) {
        guard let sprite = currentSprite else { return }
        
        // Aquí implementarías el diálogo de edición para el tween específico
        // Por ahora solo mostraremos un log
        print("Editing \(type) tween at index \(index)")
        
        // Crear un diálogo de edición (simplificado para este ejemplo)
        // En una implementación completa, aquí crearías un panel flotante con campos editables
    }
    

    private func formatValue(_ value: Any) -> String {
        if let point = value as? CGPoint {
            return "(X: \(Int(point.x)), Y: \(Int(point.y)))"
        } else if let color = value as? SKColor {
            return "RGB"
        } else if let number = value as? CGFloat {
            return String(format: "%.1f", number)
        } else {
            return "\(value)"
        }
    }
}

// Estructura auxiliar para representar la información de un tween
struct TweenInfo {
    let startTime: Int
    let endTime: Int
    let startValue: Any
    let endValue: Any
    let easing: Easing
}
