//
//  HorizontalContainer.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

class HorizontalContainer: SKNode {
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
        verticalAlignment: VerticalAlignment = .center,
        horizontalAlignment: HorizontalAlignment = .left,
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
        backgroundNode?.strokeColor = backgroundColor
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
        
        // Calculate the height based on the tallest child
        let containerHeight = childNodes.map { node -> CGFloat in
            return node.calculateAccumulatedFrame().height
        }.max() ?? 0
        
        // Calculate the total width
        var totalWidth: CGFloat = 0
        for (index, node) in childNodes.enumerated() {
            totalWidth += node.calculateAccumulatedFrame().width
            if index < childNodes.count - 1 {
                totalWidth += spacing
            }
        }
        
        // Update container size with padding
        containerSize = CGSize(
            width: totalWidth + padding.width * 2,
            height: containerHeight + padding.height * 2
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
        var currentX: CGFloat
        
        // Set starting X position based on horizontal alignment
        switch horizontalAlignment {
        case .left:
            currentX = -containerSize.width/2 + padding.width
        case .center:
            currentX = -totalWidth/2
        case .right:
            currentX = containerSize.width/2 - padding.width - childNodes.first!.calculateAccumulatedFrame().width
        }
        
        for node in childNodes {
            let nodeHeight = node.calculateAccumulatedFrame().height
            let nodeWidth = node.calculateAccumulatedFrame().width
            
            // Set Y position based on vertical alignment
            var yPos: CGFloat
            switch verticalAlignment {
            case .top:
                yPos = containerSize.height/2 - padding.height - nodeHeight/2
            case .center:
                yPos = 0
            case .bottom:
                yPos = -containerSize.height/2 + padding.height + nodeHeight/2
            }
            
            // Position the node
            node.position = CGPoint(x: currentX + nodeWidth/2, y: yPos)
            
            // Move right for the next node
            currentX += nodeWidth + spacing
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
    
    func setFullWidth(width: CGFloat) {
        
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
