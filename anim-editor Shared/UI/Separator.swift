//
//  Separator.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

class Separator: SKNode {
    private var lineNode: SKShapeNode
    private var lineHeight: CGFloat
    private var lineColor: SKColor
    private var width: CGFloat
    
    init(width: CGFloat = 0, height: CGFloat = 1, color: SKColor = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)) {
        self.width = width
        self.lineHeight = height
        self.lineColor = color
        
        // Crear el nodo para la línea
        lineNode = SKShapeNode()
        
        // Si el ancho no es 0, crear la línea inmediatamente
        if width > 0 {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -width/2, y: 0))
            path.addLine(to: CGPoint(x: width/2, y: 0))
            lineNode.path = path
        }
        
        lineNode.strokeColor = color
        lineNode.lineWidth = height
        
        super.init()
        addChild(lineNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func calculateAccumulatedFrame() -> CGRect {
        let baseFrame = super.calculateAccumulatedFrame()
        if baseFrame.height < lineHeight {
            return CGRect(
                x: baseFrame.origin.x,
                y: baseFrame.origin.y - lineHeight/2,
                width: baseFrame.width,
                height: 4
            )
        }
        return baseFrame
    }
    
    // Método para actualizar el ancho cuando se conoce el ancho del contenedor
    func setWidth(_ newWidth: CGFloat) {
        width = newWidth
        
        // Recrear el path con el nuevo ancho
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -width/2, y: 0))
        path.addLine(to: CGPoint(x: width/2, y: 0))
        lineNode.path = path
    }
    
    // Método para actualizar el color
    func setColor(_ color: SKColor) {
        lineColor = color
        lineNode.strokeColor = color
    }
    
    // Método para actualizar la altura (grosor) de la línea
    func setHeight(_ height: CGFloat) {
        lineHeight = height
        lineNode.lineWidth = height
    }
}
