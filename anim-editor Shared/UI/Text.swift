//
//  Text.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

enum TextType {
    case paragraph
    case title
    case capitalTitle
}

class Text: SKNode {
    init(text: String, fontSize: CGFloat, color: SKColor, type: TextType, letterSpacing: CGFloat = 2.0, width: CGFloat? = nil) {
        super.init()

        let processedText: String
        let fontName: String
        let processedFontSize: CGFloat

        switch type {
        case .paragraph:
            fontName = "HelveticaNeue"
            processedFontSize = fontSize
            processedText = text
        case .title:
            fontName = "HelveticaNeue"
            processedFontSize = fontSize
            processedText = text
        case .capitalTitle:
            fontName = "HelveticaNeue-Bold"
            processedFontSize = fontSize
            processedText = text.uppercased()
        }

        // Verificar si necesitamos truncar el texto
        var textToRender = processedText

        
        // Calcular el ancho total del texto
        var totalWidth: CGFloat = 0
        var characterWidths: [CGFloat] = []
        
        // Primero calculamos el ancho de cada caracter
        for character in processedText {
            let letterLabel = SKLabelNode(text: String(character))
            letterLabel.fontSize = processedFontSize
            letterLabel.fontName = fontName
            let charWidth = letterLabel.calculateAccumulatedFrame().width + letterSpacing
            characterWidths.append(charWidth)
            totalWidth += charWidth
        }
        totalWidth -= letterSpacing // Ajustar el ancho total para el último caracter
        
        // Si se especificó un ancho máximo, usarlo
        if let maxWidth = width {
            // Si el texto es más largo que el ancho máximo, truncarlo
            if totalWidth > maxWidth {
                var availableWidth = maxWidth - letterSpacing * 3 // Espacio para "..."
                var truncatedText = ""
                
                for (index, character) in processedText.enumerated() {
                    if availableWidth - characterWidths[index] >= 0 {
                        truncatedText.append(character)
                        availableWidth -= characterWidths[index]
                    } else {
                        break
                    }
                }
                
                textToRender = truncatedText + "..."
                
                // Recalcular el ancho total para el texto truncado
                totalWidth = maxWidth
            } else {
                // Si el texto es más corto que el ancho máximo, usar el ancho máximo
                totalWidth = maxWidth
            }
        }
        
        // Crear un nodo de fondo para ocupar el ancho completo si se especificó
        if let maxWidth = width {
            let backgroundNode = SKShapeNode(rectOf: CGSize(width: maxWidth, height: processedFontSize))
            backgroundNode.fillColor = .red
            backgroundNode.strokeColor = .red
            addChild(backgroundNode)
        }
        
        // Posicionar cada letra
        var currentX: CGFloat = -totalWidth / 2 // Iniciar desde la izquierda
        for character in textToRender {
            let letterLabel = SKLabelNode(text: String(character))
            letterLabel.fontColor = color
            letterLabel.fontSize = processedFontSize
            letterLabel.fontName = fontName
            
            // Cambiar los modos de alineación para corregir el problema
            letterLabel.horizontalAlignmentMode = .left
            letterLabel.verticalAlignmentMode = .baseline // Usar baseline en lugar de top
            
            letterLabel.position = CGPoint(x: currentX, y: 0)
            addChild(letterLabel)

            currentX += letterLabel.calculateAccumulatedFrame().width + letterSpacing
        }
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
