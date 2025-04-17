//
//  InputFieldNone.swift
//  anim-editor
//
//  Created by José Puma on 31-12-24.
//

import SpriteKit

class InputFieldNode: SKNode {
    private let backgroundNode: SKShapeNode
    private let textNode: SKLabelNode
    private var textField: NSTextField?
    private var isEditing = false  // Nueva bandera para evitar ediciones duplicadas
    
    var value: String
    private weak var parentWindow: NSWindow?  // Mantener una referencia débil a la ventana
    
    init(text: String, width: CGFloat = 100, height: CGFloat = 20) {
        self.value = text
        
        backgroundNode = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 5)
        backgroundNode.fillColor = .gray
        backgroundNode.strokeColor = .lightGray  // Añade un borde para mejor visibilidad
        
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
        // Evitar múltiples campos de texto
        if !isEditing {
            startEditing(in: self.scene!.view!)
        }
    }
    
    func startEditing(in view: SKView) {
        // Evitar múltiples llamadas
        if isEditing || textField != nil {
            return
        }
        
        isEditing = true
        textNode.isHidden = true
        
        // Guardar referencia a la ventana
        parentWindow = view.window
        
        // Crear campo de texto en la posición correcta
        let scenePoint = self.convert(.zero, to: self.scene!)
        let viewPoint = view.convert(scenePoint, from: self.scene!)
        
        // Ajustar posición para alinear con el nodo
        let yPosition = viewPoint.y - backgroundNode.frame.height / 2
        let xPosition = viewPoint.x - backgroundNode.frame.width / 2
        
        let textField = NSTextField(frame: NSRect(
            x: xPosition,
            y: yPosition,
            width: backgroundNode.frame.width,
            height: backgroundNode.frame.height
        ))
        
        // Configurar el campo de texto
        textField.stringValue = value
        textField.font = NSFont(name: "Helvetica", size: 12)
        textField.isBezeled = false
        textField.drawsBackground = true
        textField.backgroundColor = NSColor.darkGray
        textField.textColor = .white
        textField.isBordered = true
        textField.focusRingType = .none
        textField.alignment = .left
        
        // Configurar delegado y acción
        textField.delegate = self as? NSTextFieldDelegate
        textField.target = self
        textField.action = #selector(textFieldAction)
        
        // Añadir al view y enfocar
        view.addSubview(textField)
        view.window?.makeFirstResponder(textField)
        self.textField = textField
        
        // Registrar notificación para detectar cuando se termina de editar
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textFieldDidEndEditing),
            name: NSControl.textDidEndEditingNotification,
            object: textField
        )
        
        // Registrar notificación para el redimensionamiento de la ventana
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: view.window
        )
    }
    
    @objc func windowDidResize(notification: Notification) {
        guard let view = self.scene?.view, let textField = self.textField else { return }
        
        // Recalcular posición cuando cambia el tamaño de la ventana
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
        // Evitar múltiples llamadas
        guard isEditing, let textField = self.textField else { return }
        
        isEditing = false
        
        // Actualizar el valor y el nodo de texto
        if !textField.stringValue.isEmpty {
            value = textField.stringValue
            textNode.text = value
            
            // Notificar al padre del cambio
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
        // Asegurarse de eliminar todas las notificaciones y recursos
        NotificationCenter.default.removeObserver(self)
        textField?.removeFromSuperview()
    }
}
