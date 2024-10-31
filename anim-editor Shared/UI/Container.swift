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
        
        // Agregar un nodo de fondo para debugging
        let background = SKShapeNode(rectOf: size)
        background.fillColor = .clear
        background.strokeColor = .red
        background.lineWidth = 1
        addChild(background)
        
        // Agregar todos los nodos del builder
        let nodes = content()
        nodes.forEach { node in
            contents.append(node)
            addChild(node)
        }
        updateLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func updateLayout() {
        var currentPosition: CGPoint = CGPoint(x: padding, y: -padding)
        
        if autoSize {
            var totalWidth: CGFloat = padding * 2
            var totalHeight: CGFloat = padding * 2
            
            for (index, node) in contents.enumerated() {
                if axis == .horizontal {
                    totalWidth += node.frame.width
                    totalHeight = max(totalHeight, node.frame.height + padding * 2)
                    if index < contents.count - 1 {
                        totalWidth += spacing
                    }
                } else {
                    totalWidth = max(totalWidth, node.frame.width + padding * 2)
                    totalHeight += node.frame.height
                    if index < contents.count - 1 {
                        totalHeight += spacing
                    }
                }
            }
            
            size = CGSize(width: totalWidth, height: totalHeight)
            (children.first as? SKShapeNode)?.path = CGPath(rect: CGRect(origin: .zero, size: size), transform: nil)
        }
        
        for (index, node) in contents.enumerated() {
            // Ajustar la posición según la alineación
            switch nodeAlignment {
            case .left:
                node.position = CGPoint(x: currentPosition.x, y: currentPosition.y)
            case .center:
                node.position = CGPoint(x: currentPosition.x + (size.width / 2) - (node.frame.width / 2), y: currentPosition.y)
            case .right:
                node.position = CGPoint(x: currentPosition.x + size.width - node.frame.width, y: currentPosition.y)
            }
            
            if axis == .horizontal {
                currentPosition.x += node.frame.width + spacing
            } else {
                currentPosition.y -= node.frame.height + spacing
            }
        }
        
        updatePosition()
    }

    func updatePosition() {
        guard let scene = parentScene else { return }
        let sceneSize = scene.size
        
        var position = CGPoint.zero
        switch alignment {
            case .topLeft:
                position = CGPoint(x: -sceneSize.width / 2, y: sceneSize.height / 2)
            case .topCenter:
                position = CGPoint(x: 0, y: sceneSize.height / 2)
            case .topRight:
                position = CGPoint(x: sceneSize.width / 2 - size.width, y: sceneSize.height / 2)
            case .centerLeft:
                position = CGPoint(x: -sceneSize.width / 2, y: 0)
            case .center:
                position = CGPoint(x: 0, y: 0)
            case .centerRight:
                position = CGPoint(x: sceneSize.width / 2 - size.width, y: 0)
            case .bottomLeft:
                position = CGPoint(x: -sceneSize.width / 2, y: -sceneSize.height / 2)
            case .bottomCenter:
                position = CGPoint(x: 0, y: -sceneSize.height / 2)
            case .bottomRight:
                position = CGPoint(x: sceneSize.width / 2 - size.width, y: -sceneSize.height / 2)
            }
        //let anchorPoint = CGPoint(x: 0.5, y: 0.5)
        //self.position = CGPoint(x: position.x + (size.width * anchorPoint.x), y: position.y - (size.height * anchorPoint.y))
        self.position = position
        
        print(position)
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
    static func label(_ text: String, fontSize: CGFloat = 20) -> SKLabelNode {
        let label = SKLabelNode(text: text)
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
