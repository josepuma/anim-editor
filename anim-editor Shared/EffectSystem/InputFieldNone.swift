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
    private var scrollView: NSScrollView?
    
    var value: String
    private weak var parentWindow: NSWindow?
    
    // Callback para cuando el valor cambia
    var onTextChanged: ((String) -> Void)?
    
    init(text: String, width: CGFloat = 100, height: CGFloat = 20) {
        self.value = text
        
        backgroundNode = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 5)
        backgroundNode.fillColor = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
        backgroundNode.strokeColor = .clear
        backgroundNode.lineWidth = 1
        
        textNode = SKLabelNode(text: text)
        textNode.fontName = "Helvetica"
        textNode.fontSize = 12
        textNode.fontColor = .white
        textNode.verticalAlignmentMode = .center
        textNode.horizontalAlignmentMode = .left
        textNode.numberOfLines = 1
        
        super.init()
        
        addChild(backgroundNode)
        addChild(textNode)
        isUserInteractionEnabled = true
        textNode.position = CGPoint(x: -backgroundNode.frame.width / 2 + 5, y: 0)
        
        // Asegurarnos de que este nodo tenga un nombre único
        if name == nil {
            name = "input_" + UUID().uuidString
        }
        updateDisplayedText()
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
        
        let padding: CGFloat = 0
        let textSize = textNode.frame.size
        let width = max(backgroundNode.frame.width, textSize.width + padding * 2)
        let height = max(backgroundNode.frame.height, textSize.height + padding * 2)
        
        print(height)
        
        let xPosition = (viewPoint.x - width / 2) + 5
        let yPosition = (viewPoint.y - height / 2) + 5
        
        let textField = NSTextField(frame: NSRect(
            x: xPosition,
            y: yPosition,
            width: backgroundNode.frame.width - 10,
            height: textNode.frame.height
        ))
        
        textField.stringValue = value
        textField.font = NSFont(name: "Helvetica", size: 12)
        textField.isBezeled = false
        textField.drawsBackground = true
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.isBordered = false
        textField.focusRingType = .none
        textField.alignment = .left
        textField.focusRingType = .none
        textField.isEditable = true
        textField.isSelectable = true
        textField.usesSingleLineMode = true
        
        textField.delegate = self as? NSTextFieldDelegate
        textField.target = self
        textField.action = #selector(textFieldAction)
        
        print("textField.intrinsicContentSize after setup: \(textField.intrinsicContentSize)")
        
        //view.addSubview(textField)
        let textHeight = textField.intrinsicContentSize.height

       let scrollView = NSScrollView(frame: NSRect(
           x: xPosition,
           y: yPosition,
           width: backgroundNode.frame.width - 10,
           height: textHeight // Usar la altura intrínseca
       ))
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textField
        scrollView.drawsBackground = false
        scrollView.focusRingType = .none
        
        print("textField.frame.height after creation: \(textField.frame.height)")

        view.addSubview(scrollView)
        self.scrollView = scrollView
        self.textField = textField
        
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
    
    private func updateDisplayedText() {
        let maxWidth = backgroundNode.frame.width - 10 // padding
        let fullText = value
        
        // Crear un label temporal para medir el ancho
        let tempLabel = SKLabelNode(fontNamed: textNode.fontName)
        tempLabel.fontSize = textNode.fontSize
        tempLabel.text = fullText
        tempLabel.horizontalAlignmentMode = .left
        tempLabel.verticalAlignmentMode = .center
        
        // Medir el ancho
        let textWidth = tempLabel.frame.width
        
        if textWidth <= maxWidth {
            textNode.text = fullText
        } else {
            // Truncar manualmente
            var truncatedText = fullText
            while truncatedText.count > 0 {
                truncatedText.removeLast()
                tempLabel.text = truncatedText + "…"
                if tempLabel.frame.width <= maxWidth {
                    break
                }
            }
            textNode.text = truncatedText + "…"
        }
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
            //textNode.text = value
            updateDisplayedText()
            
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
        //textField.removeFromSuperview()
        scrollView?.removeFromSuperview()
        scrollView = nil
        self.textField = nil
        
        // Eliminar las notificaciones
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        textField?.removeFromSuperview()
    }
}
