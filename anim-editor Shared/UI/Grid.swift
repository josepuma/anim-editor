//
//  Grid.swift
//  anim-editor
//
//  Created by José Puma on 12-04-25.
//

import SpriteKit

class Grid: SKNode {
    // Propiedades de la cuadrícula
    private var gridWidth: CGFloat = 854
    private var gridHeight: CGFloat = 480
    private var cellSize: CGFloat = 50 // Tamaño de cada celda
    private var centerCoordLabel: SKLabelNode!
    
    // Nodos para visualización
    private var gridLines: SKShapeNode!
    private var coordsLabel: SKLabelNode!
    private var currentPosition: CGPoint = .zero
    
    // Factores de escala
    private var scaleFactorX: CGFloat = 1.0
    private var scaleFactorY: CGFloat = 1.0
    
    var onMousePositionChange: ((String) -> Void)?
    
    init(cellSize: CGFloat = 50) {
        self.cellSize = cellSize
        super.init()
        
        setupGrid()
        setupCoordinatesLabel()
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGrid() {
        // Crear un nodo para las líneas de la cuadrícula
        gridLines = SKShapeNode()
        gridLines.strokeColor = SKColor(white: 1.0, alpha: 0.2) // Líneas blancas semi-transparentes
        gridLines.lineWidth = 1.0
        addChild(gridLines)
        
        // Dibujar la cuadrícula
        drawGrid()
    }
    
    private func setupCoordinatesLabel() {
        let margin: CGFloat = 5
        // Etiqueta para mostrar coordenadas
        coordsLabel = SKLabelNode(text: "X: 0, Y: 0")
        coordsLabel.fontName = "HelveticaNeue-Medium"
        coordsLabel.fontSize = 10
        coordsLabel.fontColor = .white
        coordsLabel.horizontalAlignmentMode = .left
        coordsLabel.zPosition = 10
        coordsLabel.position = CGPoint(
            x: -gridWidth/2 - margin + 20,
            y: gridHeight/2 - margin - 16
        )
        addChild(coordsLabel)
    }
    
    private func drawGrid() {
        // Crear path para las líneas regulares del grid
        let regularPath = CGMutablePath()
        
        // Calcular los límites de la cuadrícula
        let startX = -gridWidth/2
        let endX = gridWidth/2
        let startY = -gridHeight/2
        let endY = gridHeight/2
        
        // Dibujar líneas verticales, saltando la línea central (x = 0)
        for x in stride(from: -cellSize, to: startX, by: -cellSize) {
            regularPath.move(to: CGPoint(x: x, y: startY))
            regularPath.addLine(to: CGPoint(x: x, y: endY))
        }
        
        for x in stride(from: cellSize, through: endX, by: cellSize) {
            regularPath.move(to: CGPoint(x: x, y: startY))
            regularPath.addLine(to: CGPoint(x: x, y: endY))
        }
        
        // Dibujar líneas horizontales, saltando la línea central (y = 0)
        for y in stride(from: -cellSize, to: startY, by: -cellSize) {
            regularPath.move(to: CGPoint(x: startX, y: y))
            regularPath.addLine(to: CGPoint(x: endX, y: y))
        }
        
        for y in stride(from: cellSize, through: endY, by: cellSize) {
            regularPath.move(to: CGPoint(x: startX, y: y))
            regularPath.addLine(to: CGPoint(x: endX, y: y))
        }
        
        // Asignar path a las líneas regulares
        gridLines.path = regularPath
        
        // Crear un nodo separado para las líneas centrales resaltadas
        let centerPath = CGMutablePath()
        
        // Línea central horizontal (eje X)
        centerPath.move(to: CGPoint(x: startX, y: 0))
        centerPath.addLine(to: CGPoint(x: endX, y: 0))
        
        // Línea central vertical (eje Y)
        centerPath.move(to: CGPoint(x: 0, y: startY))
        centerPath.addLine(to: CGPoint(x: 0, y: endY))
        
        // Crear nodo para las líneas centrales
        let centerLines = SKShapeNode()
        centerLines.path = centerPath
        centerLines.strokeColor = SKColor(white: 1.0, alpha: 0.12) // Más brillante para destacar
        centerLines.lineWidth = 1.0
        addChild(centerLines)
    }
    
    // Actualizar según el tamaño de la pantalla
    func adjustForScreenSize(screenSize: CGSize) {
        // Asegurarnos de que el grid siempre ocupe todo el espacio disponible
        // manteniendo la misma escala en ambos ejes
        
        // Primero, actualizamos los factores de escala
        scaleFactorX = screenSize.width / gridWidth
        scaleFactorY = screenSize.height / gridHeight
        
        // Elegimos el factor que hará que el grid ocupe toda la pantalla
        // sin distorsionar la relación de aspecto
        let scaleFactor = min(scaleFactorX, scaleFactorY)
        
        // Aplicamos la escala
        self.setScale(scaleFactor)
        drawGrid()
    }
    
    func worldToGridCoordinates(_ worldPoint: CGPoint) -> CGPoint {
        // Verificar si estamos en una escena
        guard let scene = self.scene else {
            // Si no estamos en una escena, devolvemos las coordenadas tal cual o un valor por defecto
            return CGPoint(x: 0, y: 0)
        }
        
        // Ahora es seguro usar scene (sin el !)
        let localPoint = convert(worldPoint, from: scene)
        
        // Resto del código...
        let gridX = localPoint.x + gridWidth/2
        let gridY = gridHeight/2 - localPoint.y
        
        return CGPoint(x: gridX, y: gridY)
    }
    
    #if os(OSX)
    // Esta es una función que se llama desde GameScene, ya que SpriteKit
    // no propaga eventos mouseMoved automáticamente a los nodos hijos
    func handleMouseMovement(location: CGPoint) {
        // Solo actualizar si el grid está en la escena
        if self.parent != nil {
            updateCoordinatesDisplay(worldPosition: location)
        }
    }
    #endif
    
    private func updateCoordinatesDisplay(worldPosition: CGPoint) {
        let gridPosition = worldToGridCoordinates(worldPosition)
        
        // Redondear a enteros para una visualización más limpia
        let roundedX = Int(gridPosition.x)
        let roundedY = Int(gridPosition.y)
        let newText = "X: \(roundedX - 107) - Y: \(roundedY)"
        // Actualizar la etiqueta
        coordsLabel.text = newText
        
        // Guardar la posición actual para referencia
        currentPosition = CGPoint(x: roundedX, y: roundedY * -1)
        
        onMousePositionChange?(newText)
        
    }
    
    // Método para obtener la posición actual en el grid
    func getCurrentGridPosition() -> CGPoint {
        return currentPosition
    }
}
