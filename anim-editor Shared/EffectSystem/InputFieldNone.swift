//
//  InputFieldNone.swift
//  anim-editor
//
//  Created by José Puma on 31-12-24.
//

import SpriteKit
import Foundation
import ObjectiveC

class InputFieldNode: SKNode {
    private let backgroundNode: SKShapeNode
    private let textNode: SKLabelNode
    private var textField: NSTextField?
    private var isEditing = false
    
    var value: String
    private weak var parentWindow: NSWindow?
    
    // Callback para cuando el valor cambia
    var onTextChanged: ((String) -> Void)?
    
    init(text: String, width: CGFloat = 100, height: CGFloat = 20) {
        self.value = text
        
        backgroundNode = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 5)
        backgroundNode.fillColor = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
        backgroundNode.strokeColor = NSColor(white: 0.5, alpha: 0.5)
        backgroundNode.lineWidth = 1
        
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
        textNode.position = CGPoint(x: -backgroundNode.frame.width / 2 + 5, y: 0)
        
        // Asegurarnos de que este nodo tenga un nombre único
        if name == nil {
            name = "input_" + UUID().uuidString
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        if !isEditing {
            startEditing(in: self.scene!.view!)
        }
    }
    
    func startEditing(in view: SKView) {
        if isEditing || textField != nil {
            return
        }
        
        isEditing = true
        textNode.isHidden = true
        
        parentWindow = view.window
        
        let scenePoint = self.convert(.zero, to: self.scene!)
        let viewPoint = view.convert(scenePoint, from: self.scene!)
        
        let yPosition = viewPoint.y - backgroundNode.frame.height / 2
        let xPosition = viewPoint.x - backgroundNode.frame.width / 2
        
        let textField = NSTextField(frame: NSRect(
            x: xPosition,
            y: yPosition,
            width: backgroundNode.frame.width,
            height: backgroundNode.frame.height
        ))
        
        textField.stringValue = value
        textField.font = NSFont(name: "Helvetica", size: 12)
        textField.isBezeled = false
        textField.drawsBackground = true
        textField.backgroundColor = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
        textField.textColor = .white
        textField.isBordered = true
        textField.focusRingType = .none
        textField.alignment = .left
        
        textField.delegate = self as? NSTextFieldDelegate
        textField.target = self
        textField.action = #selector(textFieldAction)
        
        view.addSubview(textField)
        view.window?.makeFirstResponder(textField)
        self.textField = textField
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldDidEndEditing),
            name: NSControl.textDidEndEditingNotification,
            object: textField
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: view.window
        )
    }
    
    @objc func windowDidResize(notification: Notification) {
        guard let view = self.scene?.view, let textField = self.textField else { return }
        
        let scenePoint = self.convert(.zero, to: self.scene!)
        let viewPoint = view.convert(scenePoint, from: self.scene!)
        
        let yPosition = viewPoint.y - backgroundNode.frame.height / 2
        let xPosition = viewPoint.x - backgroundNode.frame.width / 2
        
        textField.frame.origin = CGPoint(x: xPosition, y: yPosition)
    }
    
    @objc func textFieldAction() {
        endEditing()
    }
    
    @objc func textFieldDidEndEditing(notification: Notification) {
        endEditing()
    }
    
    private func endEditing() {
        guard isEditing, let textField = self.textField else { return }
        
        isEditing = false
        
        // Actualizar el valor y el nodo de texto
        if !textField.stringValue.isEmpty {
            let oldValue = value
            value = textField.stringValue
            textNode.text = value
            
            // Notificar al callback del cambio
            if oldValue != value && onTextChanged != nil {
                onTextChanged?(value)
            }
            
            // Notificar al padre del cambio - para compatibilidad con código existente
            if let parentNode = parent as? EffectsTableNode,
               let nodeName = name {
                let components = nodeName.split(separator: "_").map { String($0) }
                if components.count >= 3, let index = Int(components[1]) {
                    let parameter = components.dropFirst(2).joined(separator: "_")
                    
                    // Convertir el valor al tipo apropiado
                    let newValue: Any
                    if parameter.lowercased().contains("time") || parameter.lowercased().contains("count") {
                        newValue = Int(value) ?? 0
                    } else if parameter.lowercased().contains("scale") ||
                              parameter.lowercased().contains("alpha") {
                        newValue = Double(value) ?? 0.0
                    } else {
                        newValue = value
                    }
                    
                    parentNode.updateEffectParameter(at: index, parameter: parameter, value: newValue)
                }
            }
        }
        
        // Mostrar el texto nuevamente
        textNode.isHidden = false
        
        // Limpiar
        textField.removeFromSuperview()
        self.textField = nil
        
        // Eliminar las notificaciones
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        textField?.removeFromSuperview()
    }
}
