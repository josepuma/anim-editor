//
//  Container.swift
//  anim-editor
//
//  Created by José Puma on 31-10-24.
//

import SpriteKit

enum LayoutAlignment {
    case topLeft, topCenter, topRight
    case centerLeft, center, centerRight
    case bottomLeft, bottomCenter, bottomRight
}

enum NodeAlignment {
    case left, center, right
}

enum LayoutAxis {
    case horizontal, vertical
}

class Container: SKNode {
    private var alignment: LayoutAlignment
    private var padding: CGFloat
    private var spacing: CGFloat
    private var axis: LayoutAxis
    private var size: CGSize
    private var autoSize: Bool
    private var contents: [SKNode] = []
    private var nodeAlignment: NodeAlignment
    private weak var parentScene: SKScene?
    
    init(alignment: LayoutAlignment = .topLeft,
         padding: CGFloat = 0,
         spacing: CGFloat = 0,
         axis: LayoutAxis = .vertical,
         size: CGSize = .zero,
         autoSize: Bool = true,
         scene: SKScene,
         nodeAlignment: NodeAlignment = .left,
         @ContainerBuilder content: () -> [SKNode]) {
        self.alignment = alignment
        self.padding = padding
        self.spacing = spacing
        self.axis = axis
        self.size = size
        self.autoSize = autoSize
        self.parentScene = scene
        self.nodeAlignment = nodeAlignment
        super.init()
        
        self.name = "container"
        
        
        // Add all nodes from builder
        let nodes = content()
        nodes.forEach { node in
            if let label = node as? SKLabelNode {
                // Configuración específica para SKLabelNode
                switch nodeAlignment {
                case .left:
                    label.horizontalAlignmentMode = .left
                case .center:
                    label.horizontalAlignmentMode = .center
                case .right:
                    label.horizontalAlignmentMode = .right
                }
                
                // Configuración vertical según el alignment
                if alignment == .topLeft || alignment == .topCenter || alignment == .topRight {
                    label.verticalAlignmentMode = .top
                } else if alignment == .bottomLeft || alignment == .bottomCenter || alignment == .bottomRight {
                    label.verticalAlignmentMode = .bottom
                } else {
                    label.verticalAlignmentMode = .center
                }
            }
            contents.append(node)
            addChild(node)
        }
        updateLayout()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLayout() {
        var currentPosition = CGPoint(x: padding, y: -padding)
       
        if autoSize {
            var totalWidth: CGFloat = padding * 2
            var totalHeight: CGFloat = padding * 2
            for (index, node) in contents.enumerated() {
                let nodeHeight = node is SKLabelNode ? (node as! SKLabelNode).fontSize : node.frame.height
                let nodeWidth = node.frame.width
                
                if axis == .horizontal {
                    totalWidth += nodeWidth
                    if index < contents.count - 1 {
                        totalWidth += spacing
                    }
                } else {
                    totalWidth = max(totalWidth, nodeWidth + padding * 2)
                    totalHeight += nodeHeight
                    if index < contents.count - 1 {
                        totalHeight += spacing
                    }
                }
            }
            
            size = CGSize(width: totalWidth, height: totalHeight)
        }
        
        for node in contents {
            var nodePosition = currentPosition
            let nodeHeight = node is SKLabelNode ? (node as! SKLabelNode).fontSize : node.frame.height
            // Ajuste para la posición horizontal basada en nodeAlignment
            switch nodeAlignment {
                case .left:
                    nodePosition.x = padding
                case .center:
                    nodePosition.x = 0
                case .right:
                    nodePosition.x = 1
            }
            
            node.position = nodePosition
            
            // Mueve hacia abajo el currentPosition.y para el próximo nodo
            currentPosition.y -= nodeHeight + spacing
        }
        
        updatePosition()
    }

        func updatePosition() {
            guard let scene = parentScene else { return }
            let sceneSize = scene.size
            
            // Calculate X position based on layout alignment and node alignment
            let xPosition: CGFloat = {
                switch (alignment, nodeAlignment) {
                // Top alignments
                case (.topLeft, .left), (.centerLeft, .left), (.bottomLeft, .left):
                    return -sceneSize.width / 2
                case (.topLeft, .center), (.centerLeft, .center), (.bottomLeft, .center):
                    return -sceneSize.width / 2 + size.width / 2
                case (.topLeft, .right), (.centerLeft, .right), (.bottomLeft, .right):
                    return -sceneSize.width / 2 + size.width
                    
                case (.topCenter, .left), (.center, .left), (.bottomCenter, .left):
                    return -size.width / 2
                case (.topCenter, .center), (.center, .center), (.bottomCenter, .center):
                    return 0
                case (.topCenter, .right), (.center, .right), (.bottomCenter, .right):
                    return size.width / 2
                    
                case (.topRight, .left), (.centerRight, .left), (.bottomRight, .left):
                    return sceneSize.width / 2 - size.width
                case (.topRight, .center), (.centerRight, .center), (.bottomRight, .center):
                    return sceneSize.width / 2 - size.width / 2
                case (.topRight, .right), (.centerRight, .right), (.bottomRight, .right):
                    return sceneSize.width / 2
                }
            }()
            
            // Calculate Y position based on layout alignment
            let yPosition: CGFloat = {
                switch alignment {
                case .topLeft, .topCenter, .topRight:
                    return sceneSize.height / 2
                case .centerLeft, .center, .centerRight:
                    return 0
                case .bottomLeft, .bottomCenter, .bottomRight:
                    return -sceneSize.height / 2 + size.height
                }
            }()
            
            position = CGPoint(x: xPosition, y: yPosition)
        }
}

// Result Builder para crear contenido de forma declarativa
@resultBuilder
struct ContainerBuilder {
    static func buildBlock(_ components: SKNode...) -> [SKNode] {
        return components
    }
    
    static func buildArray(_ components: [[SKNode]]) -> [SKNode] {
        return components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [SKNode]?) -> [SKNode] {
        return component ?? []
    }
    
    static func buildEither(first component: [SKNode]) -> [SKNode] {
        return component
    }
    
    static func buildEither(second component: [SKNode]) -> [SKNode] {
        return component
    }
}

extension SKScene {
    func updateContainerLayouts() {
        enumerateChildNodes(withName: "//container") { node, _ in
            if let container = node as? Container {
                container.updatePosition()
            }
        }
    }
}

// Extensiones útiles para crear nodos comunes
extension SKNode {
    static func label(_ text: String, fontSize: CGFloat = 20, fontWeight: NSFont.Weight = .regular) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = NSFont.systemFont(ofSize: fontSize, weight: fontWeight).fontName
        label.fontSize = fontSize
        return label
    }
    
    static func sprite(imageNamed: String, size: CGSize? = nil) -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: imageNamed)
        if let size = size {
            sprite.size = size
        }
        return sprite
    }
}
