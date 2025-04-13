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
    
    init(
        spacing: CGFloat = 10,
        padding: CGSize = CGSize(width: 10, height: 10),
        verticalAlignment: VerticalAlignment = .top,
        horizontalAlignment: HorizontalAlignment = .center,
        showBackground: Bool = false,
        backgroundColor: SKColor = SKColor(white: 0.1, alpha: 0.5),
        cornerRadius: CGFloat = 8
    ) {
        self.spacing = spacing
        self.padding = padding
        self.verticalAlignment = verticalAlignment
        self.horizontalAlignment = horizontalAlignment
        self.showBackground = showBackground
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        
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
        backgroundNode?.strokeColor = .clear
        backgroundNode?.zPosition = -1 // Ensure background is behind child nodes
        if let backgroundNode = backgroundNode {
            addChild(backgroundNode)
        }
    }
    
    // Add a single node
    func addNode(_ node: SKNode) {
        childNodes.append(node)
        addChild(node)
        updateLayout()
    }
    
    // Add multiple nodes at once
    func addNodes(_ nodes: [SKNode]) {
        for node in nodes {
            childNodes.append(node)
            addChild(node)
        }
        updateLayout()
    }
    
    // Remove a node
    func removeNode(_ node: SKNode) {
        if let index = childNodes.firstIndex(of: node) {
            childNodes.remove(at: index)
            node.removeFromParent()
            updateLayout()
        }
    }
    
    // Clear all nodes
    func clearNodes() {
        for node in childNodes {
            node.removeFromParent()
        }
        childNodes.removeAll()
        updateLayout()
    }
    
    // Update the layout
    func updateLayout() {
        guard !childNodes.isEmpty else {
            containerSize = .zero
            if let backgroundNode = backgroundNode {
                backgroundNode.path = nil
            }
            return
        }
        
        // Calculate the width based on the widest child
        let containerWidth = childNodes.map { node -> CGFloat in
            return node.calculateAccumulatedFrame().width
        }.max() ?? 0
        
        // Calculate the total height
        var totalHeight: CGFloat = 0
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
                roundedRect: CGRect(x: -containerSize.width/2, y: -containerSize.height/2, width: containerSize.width, height: containerSize.height),
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
            backgroundNode.path = backgroundPath
        }
        
        // Position each node
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
