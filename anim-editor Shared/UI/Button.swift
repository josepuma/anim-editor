//
//  Button.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

enum ButtonShape {
    case circle
    case rectangle(cornerRadius: CGFloat)
}

class Button: SKNode {
    // Visual components
    private var buttonNode: SKShapeNode
    private let labelNode: SKLabelNode
    
    // Properties
    private var buttonSize: CGSize
    private var buttonShape: ButtonShape
    private var buttonColor: SKColor
    private var buttonBorderColor: SKColor
    private var textColor: SKColor
    private var buttonText: String
    private var padding: CGSize
    
    private var iconNode: SKSpriteNode?
    private var iconName: String?
    private var iconSize: CGFloat = 0
    private var iconColor: SKColor = .white
    
    // Callback for button press
    var onPress: (() -> Void)?
    
    // Constructor con tamaño explícito
    init(
        text: String,
        shape: ButtonShape = .rectangle(cornerRadius: 8),
        size: CGSize,
        buttonColor: SKColor = SKColor(white: 0.95, alpha: 1.0),
        buttonBorderColor: SKColor = SKColor(white: 0.8, alpha: 0.8),
        textColor: SKColor = .black,
        fontSize: CGFloat? = nil
    ) {
        self.buttonText = text
        self.buttonShape = shape
        self.buttonSize = size
        self.buttonColor = buttonColor
        self.buttonBorderColor = buttonBorderColor
        self.textColor = textColor
        self.padding = CGSize(width: 0, height: 0) // No padding necesario con tamaño explícito
        
        // Create the button label
        labelNode = SKLabelNode(text: text)
        labelNode.fontName = "HelveticaNeue"
        labelNode.fontSize = fontSize ?? (min(size.width, size.height) * 0.4)
        labelNode.fontColor = textColor
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        
        // Create the button background based on the shape
        switch shape {
        case .circle:
            let radius = min(size.width, size.height) / 2
            buttonNode = SKShapeNode(circleOfRadius: radius)
        case .rectangle(let cornerRadius):
            buttonNode = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        }
        
        buttonNode.fillColor = buttonColor
        buttonNode.strokeColor = buttonBorderColor
        buttonNode.lineWidth = 1.0
        
        super.init()
        
        addChild(buttonNode)
        addChild(labelNode)
        
        isUserInteractionEnabled = true
        /*drawButtonBorder()
            drawLabelBorder()
            drawIconBorder()*/
    }
    
    // Constructor con tamaño automático basado en el texto
    convenience init(
        text: String,
        shape: ButtonShape = .rectangle(cornerRadius: 8),
        padding: CGSize = CGSize(width: 8, height: 8),
        buttonColor: SKColor = SKColor(white: 0.95, alpha: 1.0),
        buttonBorderColor: SKColor = SKColor(white: 0.8, alpha: 0.8),
        textColor: SKColor = .black,
        fontSize: CGFloat = 14
    ) {
        // Calcular el tamaño del texto
        let font = NSFont(name: "HelveticaNeue", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let textAttributes = [NSAttributedString.Key.font: font]
        let textSize = (text as NSString).size(withAttributes: textAttributes)
        
        // Calcular el tamaño del botón basado en el texto y el padding
        let buttonWidth = textSize.width + padding.width * 2
        let buttonHeight = textSize.height + padding.height * 2
        
        // Si es circular, asegurar que sea un círculo perfecto
        let finalSize: CGSize
        if case .circle = shape {
            let diameter = max(buttonWidth, buttonHeight)
            finalSize = CGSize(width: diameter, height: diameter)
        } else {
            finalSize = CGSize(width: buttonWidth, height: buttonHeight)
        }
        
        self.init(
            text: text,
            shape: shape,
            size: finalSize,
            buttonColor: buttonColor,
            buttonBorderColor: buttonBorderColor,
            textColor: textColor,
            fontSize: fontSize
        )
        
        self.padding = padding
        /*drawButtonBorder()
            drawLabelBorder()
            drawIconBorder()*/
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Handle mouse clicks
    override func mouseDown(with event: NSEvent) {
        pressButton()
    }
    
    // Button press action
    func pressButton() {
        // Visual effect when clicked
        let scaleDown = SKAction.scale(to: 0.95, duration: 0.05)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.05)
        let sequence = SKAction.sequence([scaleDown, scaleUp])
        
        // Apply the animation
        buttonNode.run(sequence)
        
        // Call the callback if it exists
        onPress?()
    }
    
    // Métodos para actualizar el texto y recalcular el tamaño si es necesario
    func setText(text: String, resizeButton: Bool = false) {
        buttonText = text
        labelNode.text = text
        
        if resizeButton {
            // Calcular el nuevo tamaño basado en el texto
            let font = NSFont(name: "HelveticaNeue", size: labelNode.fontSize) ?? NSFont.systemFont(ofSize: labelNode.fontSize)
            let textAttributes = [NSAttributedString.Key.font: font]
            let textSize = (text as NSString).size(withAttributes: textAttributes)
            
            // Actualizar el tamaño del botón
            let newWidth = textSize.width + padding.width * 2
            let newHeight = textSize.height + padding.height * 2
            
            var newSize = CGSize(width: newWidth, height: newHeight)
            
            // Si es circular, mantener la forma circular
            if case .circle = buttonShape {
                let diameter = max(newWidth, newHeight)
                newSize = CGSize(width: diameter, height: diameter)
            }
            
            buttonSize = newSize
            
            // Recrear el nodo del botón con el nuevo tamaño
            switch buttonShape {
            case .circle:
                let radius = min(newSize.width, newSize.height) / 2
                let newButtonNode = SKShapeNode(circleOfRadius: radius)
                newButtonNode.fillColor = buttonColor
                newButtonNode.strokeColor = buttonBorderColor
                newButtonNode.lineWidth = 1.0
                
                buttonNode.removeFromParent()
                buttonNode = newButtonNode
                insertChild(buttonNode, at: 0)
                
            case .rectangle(let cornerRadius):
                let newButtonNode = SKShapeNode(rectOf: newSize, cornerRadius: cornerRadius)
                newButtonNode.fillColor = buttonColor
                newButtonNode.strokeColor = buttonBorderColor
                newButtonNode.lineWidth = 1.0
                
                buttonNode.removeFromParent()
                buttonNode = newButtonNode
                insertChild(buttonNode, at: 0)
            }
        }
    }
    
    func setIcon(name: String, size: CGFloat? = nil, color: SKColor = .white) {
        // Eliminar icono anterior si existe
        iconNode?.removeFromParent()

        // Guardar propiedades
        iconName = name
        iconColor = color
        iconSize = size ?? (min(buttonSize.width, buttonSize.height) * 0.6)

        // Crear nuevo icono
        iconNode = IconManager.shared.getIcon(named: name, size: iconSize, color: color)

        // Añadir el icono
        if let iconNode = iconNode {
            addChild(iconNode)

            // Calcular la posición del icono y el texto
            let textWidth = labelNode.frame.width
            let iconWidth = iconNode.frame.width
            let spacing: CGFloat = 2 // Espacio entre el icono y el texto

            // Calcular el ancho total del contenido
            let totalContentWidth = textWidth + iconWidth + spacing

            // Calcular el ancho disponible para el padding
            let availablePadding = buttonSize.width - totalContentWidth

            // Calcular el padding uniforme para ambos lados
            let uniformPadding = availablePadding / 2

            if labelNode.text != nil && labelNode.text != "" {
                // Posicionar el icono a la izquierda del texto
                iconNode.position = CGPoint(x: -totalContentWidth / 2 + iconWidth / 2, y: 0)
                labelNode.position = CGPoint(x: totalContentWidth / 2 - textWidth / 2, y: 0)

                // Recalcular el tamaño del botón incluyendo el padding uniforme
                let totalWidth = totalContentWidth + uniformPadding * 2
                let totalHeight = max(labelNode.frame.height, iconNode.frame.height) + padding.height * 2

                // Ajustar el tamaño del botón
                updateButtonSize(newWidth: totalWidth, newHeight: totalHeight)
            } else {
                // Centrar el icono si no hay texto
                iconNode.position = CGPoint(x: 0, y: 0)

                // Ajustar el tamaño del botón al tamaño del icono incluyendo el padding uniforme
                updateButtonSize(newWidth: iconWidth + uniformPadding * 2, newHeight: iconNode.frame.height + padding.height * 2)
            }
        }
    }

    // Función auxiliar para actualizar el tamaño del botón
    private func updateButtonSize(newWidth: CGFloat, newHeight: CGFloat) {
        let newSize = CGSize(width: newWidth, height: newHeight)

        // Si es circular, mantener la forma circular
        if case .circle = buttonShape {
            let diameter = max(newWidth, newHeight)
            buttonSize = CGSize(width: diameter, height: diameter)
        } else {
            buttonSize = newSize
        }

        // Recrear el nodo del botón con el nuevo tamaño
        switch buttonShape {
        case .circle:
            let radius = min(buttonSize.width, buttonSize.height) / 2
            let newButtonNode = SKShapeNode(circleOfRadius: radius)
            newButtonNode.fillColor = buttonColor
            newButtonNode.strokeColor = buttonBorderColor
            newButtonNode.lineWidth = 1.0

            buttonNode.removeFromParent()
            buttonNode = newButtonNode
            insertChild(buttonNode, at: 0)

        case .rectangle(let cornerRadius):
            let newButtonNode = SKShapeNode(rectOf: buttonSize, cornerRadius: cornerRadius)
            newButtonNode.fillColor = buttonColor
            newButtonNode.strokeColor = buttonBorderColor
            newButtonNode.lineWidth = 1.0

            buttonNode.removeFromParent()
            buttonNode = newButtonNode
            insertChild(buttonNode, at: 0)
        }
    }
    
    func setIconColor(color: SKColor) {
            iconColor = color
            
            // Actualizar el icono solo si existe
            if let iconName = iconName {
                iconNode?.removeFromParent()
                iconNode = IconManager.shared.getIcon(named: iconName, size: iconSize, color: color)
                addChild(iconNode!)
            }
        }
    
    // Methods to customize the button appearance after initialization
    func setButtonColor(color: SKColor) {
        buttonColor = color
        buttonNode.fillColor = color
    }
    
    func setBorderColor(color: SKColor) {
        buttonBorderColor = color
        buttonNode.strokeColor = color
    }
    
    func setTextColor(color: SKColor) {
        textColor = color
        labelNode.fontColor = color
    }
    
    func drawButtonBorder() {
        let borderNode = SKShapeNode()
        
        switch buttonShape {
        case .circle:
            let radius = min(buttonSize.width, buttonSize.height) / 2
            borderNode.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
        case .rectangle(let cornerRadius):
            borderNode.path = CGPath(roundedRect: CGRect(origin: CGPoint(x: -buttonSize.width / 2, y: -buttonSize.height / 2), size: buttonSize), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        }
        
        borderNode.strokeColor = .red // Color del borde de debug
        borderNode.lineWidth = 1.0
        borderNode.zPosition = 100 // Asegura que esté al frente
        addChild(borderNode)
    }
    
    func drawLabelBorder() {
        let labelBorderNode = SKShapeNode(rect: labelNode.frame)
        labelBorderNode.strokeColor = .blue // Color del borde de debug
        labelBorderNode.lineWidth = 1.0
        labelBorderNode.zPosition = 100 // Asegura que esté al frente
        addChild(labelBorderNode)
    }
    
    func drawIconBorder() {
        if let iconNode = iconNode {
            let iconBorderNode = SKShapeNode(rect: iconNode.frame)
            iconBorderNode.strokeColor = .green // Color del borde de debug
            iconBorderNode.lineWidth = 1.0
            iconBorderNode.zPosition = 100 // Asegura que esté al frente
            addChild(iconBorderNode)
        }
    }
    
    // MouseEntered for hover effect
    override func mouseEntered(with event: NSEvent) {
        // Add hover effect
        let brightenAction = SKAction.colorize(with: buttonColor.withAlphaComponent(0.8), colorBlendFactor: 0.2, duration: 0.1)
        buttonNode.run(brightenAction)
    }
    
    // MouseExited for hover effect
    override func mouseExited(with event: NSEvent) {
        // Remove hover effect
        let resetAction = SKAction.colorize(with: buttonColor, colorBlendFactor: 1.0, duration: 0.1)
        buttonNode.run(resetAction)
    }
}
