//
//  VerticalContainer.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

enum VerticalAlignment {
    case top
    case center
    case bottom
}

enum HorizontalAlignment {
    case left
    case center
    case right
}

class VerticalContainer: SKNode {
    
    private var containerHeight: CGFloat = 0
    private var contentNode: SKNode = SKNode()
    private var scrollEnabled: Bool = false
    private var scrollOffset: CGFloat = 0
    private var scrollMask: SKShapeNode?
    private var cropNode: SKCropNode?
    private var touchStartPoint: CGPoint?
    
    // Configuration
    private var spacing: CGFloat
    private var padding: CGSize
    private var verticalAlignment: VerticalAlignment
    private var horizontalAlignment: HorizontalAlignment
    
    // Content tracking
    private var childNodes: [SKNode] = []
    private var containerSize: CGSize = .zero
    
    // Background (optional)
    private var backgroundNode: SKShapeNode?
    private var showBackground: Bool
    private var backgroundColor: SKColor
    private var cornerRadius: CGFloat
    private var fullHeight: Bool = false
    
    init(
        spacing: CGFloat = 10,
        padding: CGSize = CGSize(width: 10, height: 10),
        verticalAlignment: VerticalAlignment = .top,
        horizontalAlignment: HorizontalAlignment = .center,
        showBackground: Bool = false,
        backgroundColor: SKColor = SKColor(white: 0.1, alpha: 0.5),
        cornerRadius: CGFloat = 8,
        fullHeight: Bool = false
    ) {
        self.spacing = spacing
        self.padding = padding
        self.verticalAlignment = verticalAlignment
        self.horizontalAlignment = horizontalAlignment
        self.showBackground = showBackground
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.fullHeight = fullHeight
        
        super.init()
        
        if showBackground {
            setupBackground()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBackground() {
        backgroundNode = SKShapeNode(rectOf: .zero, cornerRadius: cornerRadius)
        backgroundNode?.fillColor = backgroundColor
        backgroundNode?.strokeColor = backgroundColor
        backgroundNode?.zPosition = -1 // Ensure background is behind child nodes
        if let backgroundNode = backgroundNode {
            addChild(backgroundNode)
        }
    }
    
    // Add a single node
    func addNode(_ node: SKNode) {
        childNodes.append(node)
        //addChild(node)
        contentNode.addChild(node)
        updateLayout()
    }
    
    // Add multiple nodes at once
    func addNodes(_ nodes: [SKNode]) {
        for node in nodes {
            childNodes.append(node)
            contentNode.addChild(node) // Añadir al contentNode
        }
        updateLayout()
    }
    
    // Remove a node
    func removeNode(_ node: SKNode) {
        if let index = childNodes.firstIndex(of: node) {
            childNodes.remove(at: index)
            node.removeFromParent() // Remover del contentNode
            updateLayout()
        }
    }
    
    // Clear all nodes
    func clearNodes() {
        for node in childNodes {
            node.removeFromParent() // Remover del contentNode
        }
        childNodes.removeAll()
        updateLayout()
    }
    
    func getAvailableInnerWidth() -> CGFloat {
        return containerSize.width - padding.width * 2
    }
    
    

    // Método para ajustar elementos a ancho completo después de la configuración inicial
    func adjustChildrenWidths() {
        // Obtener el ancho disponible
        let availableWidth = getAvailableInnerWidth()
        
        // Buscar nodos que deberían ocupar todo el ancho
        for node in childNodes {
            // Solo modificar los nodos que no tienen hermanos en el mismo nivel Y
            // (esto es una simplificación - verifica si el nodo está solo en su "fila")
            let nodeLevel = node.position.y
            let nodesAtSameLevel = childNodes.filter { abs($0.position.y - nodeLevel) < 0.1 }
            
            if nodesAtSameLevel.count == 1 {
                // Este nodo está solo en su nivel
                if let button = node as? Button {
                    // Ajustar el ancho del botón
                    button.setFullWidth(width: availableWidth)
                }
                if let horizontalContainer = node as? HorizontalContainer{
                    horizontalContainer.setFullWidth(width: availableWidth)
                }
                // Puedes agregar más casos para otros tipos de nodos aquí
            }
        }
        
        // Actualizar la posición de todos los nodos una vez que se han ajustado los tamaños
        updateLayout()
    }
    
    func updateLayout() {
        guard !childNodes.isEmpty else {
            containerSize = .zero
            if let backgroundNode = backgroundNode {
                backgroundNode.path = nil
            }
            return
        }
        
        // PASO 1: Calcular dimensiones iniciales
        let newHeight = updateContainerDimensions()
        
        // PASO 2: Posicionar nodos con dimensiones originales
        positionAllNodes(totalHeight: newHeight)
        
        // PASO 3: Ajustar anchos de nodos solitarios
        adjustChildrenWidthsInternal()
        
        // PASO 4: Recalcular posiciones después del ajuste de anchos
        positionAllNodes(totalHeight: newHeight)
        
        if cropNode == nil {
            cropNode = SKCropNode()
            addChild(cropNode!)
            contentNode.removeFromParent()
            cropNode?.addChild(contentNode)
            cropNode?.zPosition = zPosition
        }

        // Crear la máscara del cropNode con una altura de 100
        /*let cropHeight: CGFloat = newHeight
        let mask = SKShapeNode(rect: CGRect(x: -containerSize.width / 2, y: -cropHeight / 2, width: containerSize.width, height: cropHeight))
  
        mask.strokeColor = .red
        mask.lineWidth = 2*/
        

        let mask = SKShapeNode(rect: CGRect(
            x: -containerSize.width / 2,
            y: -containerHeight / 2,  // empieza desde y = 0 hacia arriba
            width: containerSize.width,
            height: containerHeight
        ))

        mask.fillColor = .white  // Necesario para que funcione como máscara
        mask.strokeColor = .clear
        mask.lineWidth = 0

        cropNode?.maskNode = mask

        // Asegurarse de que contentNode esté alineado con la máscara
        contentNode.position = CGPoint(x: 0, y: (containerHeight / 2) - (newHeight / 2) - padding.height * 2)
        
        print("altura mascara:", mask.frame.height)
        print("altura total:", containerHeight)
        print("altura contenido:", newHeight)
    }


    // Calcula las dimensiones del contenedor y actualiza el fondo
    private func updateContainerDimensions() -> CGFloat {
        var totalHeight: CGFloat = 0
        // Calculate the width based on the widest child
        let containerWidth = childNodes.map { node -> CGFloat in
            return node.calculateAccumulatedFrame().width
        }.max() ?? 0
        
        // Calculate the total height
       
        for (index, node) in childNodes.enumerated() {
            totalHeight += node.calculateAccumulatedFrame().height
            if index < childNodes.count - 1 {
                totalHeight += spacing
            }
        }
        
        // Update container size with padding
        containerSize = CGSize(
            width: containerWidth + padding.width * 2,
            height: totalHeight + padding.height * 2
        )
        
        // Update background if needed
        if showBackground, let backgroundNode = backgroundNode {
            let backgroundPath = CGPath(
                roundedRect: CGRect(x: -containerSize.width/2, y: -containerHeight/2, width: containerSize.width, height: containerHeight),
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
            backgroundNode.path = backgroundPath
        }
        
        return totalHeight
    }
    
    func adjustSize(){
        if let scene = scene {
            let sceneSize = scene.size
            if fullHeight{
                containerHeight = sceneSize.height
            }else{
                containerHeight = containerSize.height
            }
            updateLayout()
        }
    }
    
    private func updateScrolling(contentHeight: CGFloat, viewHeight: CGFloat) {
        if contentHeight > viewHeight && !scrollEnabled {
            enableScrolling(viewSize: CGSize(width: containerSize.width, height: viewHeight))
        } else if contentHeight <= viewHeight && scrollEnabled {
            disableScrolling()
        } else if scrollEnabled, let cropNode = cropNode, let mask = scrollMask {
            mask.path = CGPath(rect: CGRect(origin: CGPoint(x: -containerSize.width / 2, y: -viewHeight / 2), size: CGSize(width: containerSize.width, height: viewHeight)), transform: nil)
            cropNode.maskNode = mask
        } else if !scrollEnabled, let cropNode = cropNode {
            // Asegurar que el contentNode esté directamente como hijo si no hay scroll
            contentNode.removeFromParent()
            addChild(contentNode)
            cropNode.removeFromParent()
            self.cropNode = nil
            self.scrollMask = nil
            contentNode.position = .zero
        }
    }
    
    private func enableScrolling(viewSize: CGSize) {
        scrollEnabled = true
        cropNode = SKCropNode()
        scrollMask = SKShapeNode(rect: CGRect(origin: CGPoint(x: -containerSize.width / 2, y: -viewSize.height / 2), size: viewSize))
        cropNode?.maskNode = scrollMask
        contentNode.removeFromParent()
        cropNode?.addChild(contentNode)
        addChild(cropNode!)
        cropNode?.zPosition = zPosition // Mantener el mismo zPosition
        contentNode.position = CGPoint(x: 0, y: 0) // Resetear la posición del contenido
        scrollOffset = 0
    }

    private func disableScrolling() {
        scrollEnabled = false
        if let cn = cropNode {
            contentNode.removeFromParent()
            addChild(contentNode)
            cn.removeFromParent()
            cropNode = nil
            scrollMask = nil
            contentNode.position = CGPoint(x: 0, y: 0) // Resetear la posición
        }
        scrollOffset = 0
    }


    // Posiciona todos los nodos según la alineación configurada
    private func positionAllNodes(totalHeight: CGFloat) {
        var currentY: CGFloat
        
        // Set starting Y position based on vertical alignment
        switch verticalAlignment {
            case .top:
                currentY = containerSize.height/2 - padding.height
            case .center:
                currentY = totalHeight/2
            case .bottom:
                currentY = -containerSize.height/2 + padding.height + childNodes.first!.calculateAccumulatedFrame().height/2
        }
        
        for node in childNodes {
            let nodeHeight = node.calculateAccumulatedFrame().height
            let nodeWidth = node.calculateAccumulatedFrame().width
            
            // Set X position based on horizontal alignment
            var xPos: CGFloat
            switch horizontalAlignment {
                case .left:
                    xPos = -containerSize.width/2 + padding.width + nodeWidth/2
                case .center:
                    xPos = 0
                case .right:
                    xPos = containerSize.width/2 - padding.width - nodeWidth/2
            }
            
            // Position the node
            node.position = CGPoint(x: xPos, y: currentY - nodeHeight/2)
            // Move down for the next node
            currentY -= nodeHeight + spacing
        }
    }

    // Método para ajustar los anchos de los nodos solitarios
    private func adjustChildrenWidthsInternal() {
        let availableWidth = getAvailableInnerWidth() - 4 // Margen de seguridad
        
        // Estructura para agrupar nodos por nivel Y
        var levelGroups: [CGFloat: [SKNode]] = [:]
        
        // Agrupar nodos por su posición Y actual
        for node in childNodes {
            let yLevel = node.position.y
            if levelGroups[yLevel] != nil {
                levelGroups[yLevel]?.append(node)
            } else {
                levelGroups[yLevel] = [node]
            }
        }
        
        // Ajustar el ancho de los nodos solitarios
        for (_, nodes) in levelGroups {
            if nodes.count == 1, let node = nodes.first {
                if let button = node as? Button {
                    button.setFullWidth(width: availableWidth)
                }
                if let separator = node as? Separator{
                    separator.setWidth(availableWidth)
                }
                // Añadir otros tipos si es necesario
            }
        }
    }
    
    // Toggle background visibility
    func setBackgroundVisible(_ visible: Bool) {
        if visible != showBackground {
            showBackground = visible
            
            if visible && backgroundNode == nil {
                setupBackground()
                updateLayout()
            } else if !visible && backgroundNode != nil {
                backgroundNode?.removeFromParent()
                backgroundNode = nil
            }
        }
    }
    
    // Set background color
    func setBackgroundColor(_ color: SKColor) {
        backgroundColor = color
        backgroundNode?.fillColor = color
    }
    
    // Get container size
    func getSize() -> CGSize {
        if let scene = scene {
            let sceneSize = scene.size
            if fullHeight{
                return CGSize(width: containerSize.width, height: sceneSize.height)
            }else{
                return containerSize
            }
        }
        return containerSize
    }
    
    // Adjust spacing
    func setSpacing(_ newSpacing: CGFloat) {
        spacing = newSpacing
        updateLayout()
    }
    
    // Adjust padding
    func setPadding(_ newPadding: CGSize) {
        padding = newPadding
        updateLayout()
    }
}
