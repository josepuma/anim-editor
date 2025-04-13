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
    init(text: String, fontSize: CGFloat, color: SKColor, type: TextType, letterSpacing: CGFloat = 2.0) {
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

        // Calcular el ancho total del texto
        var totalWidth: CGFloat = 0
        for character in processedText {
            let letterLabel = SKLabelNode(text: String(character))
            letterLabel.fontSize = processedFontSize
            letterLabel.fontName = fontName
            totalWidth += letterLabel.calculateAccumulatedFrame().width + letterSpacing
        }
        totalWidth -= letterSpacing // Ajustar el ancho total para el último caracter

        // Posicionar cada letra
        var currentX: CGFloat = -totalWidth / 2 // Iniciar desde la izquierda
        for character in processedText {
            let letterLabel = SKLabelNode(text: String(character))
            letterLabel.fontColor = color
            letterLabel.fontSize = processedFontSize
            letterLabel.fontName = fontName
            letterLabel.horizontalAlignmentMode = .left
            letterLabel.verticalAlignmentMode = .top

            letterLabel.position = CGPoint(x: currentX, y: 0)
            addChild(letterLabel)

            currentX += letterLabel.calculateAccumulatedFrame().width + letterSpacing
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
