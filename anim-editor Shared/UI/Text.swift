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

        var textToRender = processedText
        var renderWidth: CGFloat = 0 // Ancho del texto que realmente se renderizará
        var characterWidths: [CGFloat] = []

        // Función para calcular el ancho de un texto con la fuente y tamaño dados
        func calculateTextWidth(for text: String) -> CGFloat {
            var width: CGFloat = 0
            for (index, character) in text.enumerated() {
                let letterLabel = SKLabelNode(text: String(character))
                letterLabel.fontSize = processedFontSize
                letterLabel.fontName = fontName
                width += letterLabel.calculateAccumulatedFrame().width
                if index < text.count - 1 {
                    width += letterSpacing
                }
            }
            return width
        }

        // Si se especificó un ancho máximo, truncar el texto si es necesario
        if let maxWidth = width {
            let originalWidth = calculateTextWidth(for: processedText)
            if originalWidth > maxWidth {
                var truncatedText = ""
                var currentWidth: CGFloat = 0

                for character in processedText {
                    let tempText = truncatedText + String(character)
                    let tempWidth = calculateTextWidth(for: tempText)
                    if tempWidth + calculateTextWidth(for: "...") <= maxWidth {
                        truncatedText.append(character)
                        currentWidth = tempWidth
                    } else {
                        break
                    }
                }
                textToRender = truncatedText + "..."
                renderWidth = calculateTextWidth(for: textToRender)
            } else {
                textToRender = processedText
                renderWidth = originalWidth
            }

            // Crear y posicionar el nodo de fondo
            let backgroundNode = SKShapeNode(rectOf: CGSize(width: maxWidth, height: processedFontSize))
            backgroundNode.fillColor = .clear
            backgroundNode.strokeColor = .clear
            addChild(backgroundNode)

        } else {
            renderWidth = calculateTextWidth(for: processedText)
        }

        // Calcular altura promedio de las letras para poder centrar verticalmente
        var maxLetterHeight: CGFloat = 0
        for character in textToRender {
            let letterLabel = SKLabelNode(text: String(character))
            letterLabel.fontName = fontName
            letterLabel.fontSize = processedFontSize
            let height = letterLabel.calculateAccumulatedFrame().height
            if height > maxLetterHeight {
                maxLetterHeight = height
            }
        }

        let verticalOffset = (processedFontSize - maxLetterHeight) / 2

        // Posicionar cada letra
        var currentX: CGFloat = -renderWidth / 2 // Centrar el texto dentro de su ancho calculado
        if let maxWidth = width {
            currentX = -maxWidth / 2 // Si hay un ancho máximo, centrar el texto dentro de ese ancho
        }

        for character in textToRender {
            let letterLabel = SKLabelNode(text: String(character))
            letterLabel.fontColor = color
            letterLabel.fontSize = processedFontSize
            letterLabel.fontName = fontName

            letterLabel.horizontalAlignmentMode = .left
            letterLabel.verticalAlignmentMode = .baseline

            letterLabel.position = CGPoint(x: currentX, y: -maxLetterHeight / 2 + verticalOffset)
            addChild(letterLabel)

            currentX += letterLabel.calculateAccumulatedFrame().width + letterSpacing
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
