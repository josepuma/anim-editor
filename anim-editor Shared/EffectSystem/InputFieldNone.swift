//
//  InputFieldNone.swift
//  anim-editor
//
//  Created by José Puma on 31-12-24.
//

import SpriteKit

class InputFieldNode: SKNode {
    let backgroundNode: SKShapeNode
    let textNode: SKLabelNode
    var textField: NSTextField?
    var value: String
    
    init(text: String, width: CGFloat = 100, height: CGFloat = 20) {
        self.value = text
        
        backgroundNode = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 5)
        backgroundNode.fillColor = .gray
        
        textNode = SKLabelNode(text: text)
        textNode.fontName = "Helvetica"
        textNode.fontSize = 12
        textNode.fontColor = .white
        textNode.verticalAlignmentMode = .center
        textNode.horizontalAlignmentMode = .left
        
        super.init()
        
        addChild(backgroundNode)
        addChild(textNode)
        isUserInteractionEnabled = true
        textNode.position = CGPoint(x: -backgroundNode.frame.width / 2 + 5, y: 0) // Desplazar un poco para el margen izquierdo
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        print("InputFieldNode clicked")
        startEditing(in: self.scene!.view!)
    }
    
    func startEditing(in view: SKView) {
        // Hide the SKLabelNode (textNode) when editing starts
        textNode.isHidden = true
        
        let textField = NSTextField(frame: .zero)
        textField.stringValue = value
        textField.font = NSFont(name: "Helvetica", size: 12)
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.backgroundColor = .white
        textField.textColor = .white
        textField.target = self
        textField.action = #selector(textFieldDidEndEditing)
        
        // Get the absolute position in scene coordinates
        let scenePoint = self.convert(CGPoint.zero, to: self.scene!)
        
        // Convert scene coordinates to view coordinates
        let viewPoint = view.convert(scenePoint, from: self.scene!)
        
        // Adjust y position: Ensure it's relative to the top of the view
        let yPosition = viewPoint.y - backgroundNode.frame.height / 2
        
        // Adjust x position to align text field with background node
        let xPosition = viewPoint.x - backgroundNode.frame.width / 2
        
        // Set the frame of the NSTextField to match the background node's position and size
        textField.frame = CGRect(
            x: xPosition,   // Correct x position (aligned with SKShapeNode)
            y: yPosition,   // Correct y position (aligned with SKShapeNode)
            width: backgroundNode.frame.width,  // Same width as the background node
            height: backgroundNode.frame.height // Same height as the background node
        )
        
        // Add the NSTextField to the view and focus it
        view.addSubview(textField)
        textField.becomeFirstResponder()
        self.textField = textField
        
        // Register to receive window resize notifications
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize), name: NSWindow.didResizeNotification, object: view.window)
    }
    
    @objc func windowDidResize(notification: Notification) {
        guard let view = self.scene?.view else { return }
        
        // Recalculate position of the NSTextField when window size changes
        let scenePoint = self.convert(CGPoint.zero, to: self.scene!)
        let viewPoint = view.convert(scenePoint, from: self.scene!)
        
        // Recalculate new y position based on resized window
        let yPosition = viewPoint.y - backgroundNode.frame.height / 2
        let xPosition = viewPoint.x - backgroundNode.frame.width / 2
        
        // Update the position of the NSTextField
        textField?.frame.origin = CGPoint(x: xPosition, y: yPosition)
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        textFieldDidEndEditing()
    }
    
    @objc func textFieldDidEndEditing() {
        if let text = textField?.stringValue {
            value = text
            textNode.text = text
            textNode.isHidden = false  // Make the textNode visible again when editing ends
            
            if let parentNode = parent as? EffectsTableNode,
               let nodeName = name,
               let index = Int(nodeName.split(separator: "_")[1]),
               let parameter = nodeName.split(separator: "_").last.map(String.init) {
                
                // Get original parameter value to determine type
                let originalValue = parentNode.effects[index].parameters[parameter]
                
                // Convert according to original type
                let newValue: Any
                
                if originalValue is Int {
                    newValue = Int(text) ?? 0
                } else if originalValue is Double {
                    newValue = Double(text) ?? 0.0
                } else if originalValue is String {
                    newValue = text
                } else {
                    // Default to string if type unknown
                    newValue = text
                }
                
                parentNode.updateEffectParameter(at: index, parameter: parameter, value: newValue)
            }
        }
        textField?.removeFromSuperview()
        textField = nil
    }
}
