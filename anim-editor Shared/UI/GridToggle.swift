//
//  GridToggle.swift
//  anim-editor
//
//  Created by José Puma on 12-04-25.
//

import SpriteKit

class GridToggleButton: SKNode {
    private let buttonNode: SKShapeNode
    private let iconLabel: SKLabelNode
    private var isGridVisible = false
    
    // Callback para cuando el botón sea presionado
    var onToggle: ((Bool) -> Void)?
    
    init(size: CGFloat = 32) {
        // Crear el fondo del botón (un círculo)
        buttonNode = SKShapeNode(circleOfRadius: size/2)
        buttonNode.fillColor = SKColor(white: 0.2, alpha: 0.7)
        buttonNode.strokeColor = SKColor(white: 0.8, alpha: 0.8)
        buttonNode.lineWidth = 1.0
        
        // Usar el carácter Unicode para grid/rejilla: "⊞" o "⊟"
        iconLabel = SKLabelNode(text: "⊟")
        iconLabel.fontName = "HelveticaNeue"
        iconLabel.fontSize = size * 0.6
        iconLabel.fontColor = .white
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        
        super.init()
        
        addChild(buttonNode)
        addChild(iconLabel)
        
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Manejar clics de mouse
    override func mouseDown(with event: NSEvent) {
        toggleGridVisibility()
    }
    
    // Alternar la visibilidad del grid
    private func toggleGridVisibility() {
        isGridVisible = !isGridVisible
        
        // Cambiar el icono según el estado
        iconLabel.text = isGridVisible ? "⊞" : "⊟"
        
        // Llamar al callback si existe
        onToggle?(isGridVisible)
        
        // Efecto visual al hacer clic
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        buttonNode.run(SKAction.sequence([scaleDown, scaleUp]))
    }
}
