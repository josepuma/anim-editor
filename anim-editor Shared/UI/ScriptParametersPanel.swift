//
//  ScriptParametersPanel.swift
//  anim-editor
//
//  Created by José Puma on 17-04-25.
//

import SpriteKit

class ScriptParametersPanel: VerticalContainer {
    // Manejador de scripts
    private weak var scriptManager: ParticleScriptManager?
    
    // Script actual
    private var currentScript: String?
    
    // Componentes de UI
    private var parametersContainer: VerticalContainer!
    private var titleLabel: Text!
    private var runButton: Button!
    private var editButton: Button!
    
    // Estilos
    private var accent = NSColor(red: 202 / 255, green: 217 / 255, blue: 91 / 255, alpha: 1)
    private var backgroundColorAccent = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 0.7)
    private var backgroundColorButton = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
    private var buttonColorText = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)
    
    // Mapeo de InputFieldNodes a sus parámetros
    private var parameterFields: [String: InputFieldNode] = [:]
    
    init(scriptManager: ParticleScriptManager) {
        // Inicializar con el mismo estilo que otros contenedores
        super.init(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: true,
            backgroundColor: NSColor(red: 7 / 255, green: 7 / 255, blue: 13 / 255, alpha: 1),
            cornerRadius: 8
        )
        
        self.scriptManager = scriptManager
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Título y botones de acción
        let headerContainer = HorizontalContainer(
            spacing: 8,
            padding: CGSize(width: 0, height: 0),
            verticalAlignment: .center,
            horizontalAlignment: .center,
            showBackground: false
        )
        
        // Título
        titleLabel = Text(text: "Parámetros", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0)
        
        // Botón ejecutar
        runButton = Button(
            text: "Ejecutar",
            padding: CGSize(width: 12, height: 6),
            buttonColor: accent,
            buttonBorderColor: accent,
            textColor: .black,
            fontSize: 12
        )
        runButton.setIcon(name: "play", size: 14, color: .black)
        runButton.onPress = { [weak self] in
            self?.runScript()
        }
        
        // Botón editar
        editButton = Button(
            text: "Editar",
            padding: CGSize(width: 12, height: 6),
            buttonColor: backgroundColorButton,
            buttonBorderColor: backgroundColorButton,
            textColor: buttonColorText,
            fontSize: 12
        )
        editButton.setIcon(name: "volume", size: 14, color: buttonColorText)
        editButton.onPress = { [weak self] in
            self?.editScript()
        }
        
        // Añadir botones al header
        //headerContainer.addNodes([titleLabel, runButton, editButton])
        //addNode(headerContainer)
        
        // Separador
        addNode(Separator(width: 250, height: 1, color: backgroundColorButton))
        
        // Contenedor de parámetros
        parametersContainer = VerticalContainer(
            spacing: 8,
            padding: CGSize(width: 0, height: 0),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: false
        )
        addNode(parametersContainer)
        
        // Estado inicial
        updateButtonsState(false)
    }
    
    // Actualiza el estado de los botones
    private func updateButtonsState(_ hasScript: Bool) {
        runButton.isUserInteractionEnabled = hasScript
        editButton.isUserInteractionEnabled = hasScript
        
        if !hasScript {
            runButton.setButtonColor(color: accent.withAlphaComponent(0.5))
            editButton.setButtonColor(color: backgroundColorButton.withAlphaComponent(0.5))
        } else {
            runButton.setButtonColor(color: accent)
            editButton.setButtonColor(color: backgroundColorButton)
        }
    }
    
    // Actualizar para mostrar parámetros de un nuevo script
    func updateWithScript(_ scriptName: String?) {
        guard let scriptManager = scriptManager else { return }
        
        // Actualizar script actual
        currentScript = scriptName
        
        // Limpiar la vista
        parametersContainer.clearNodes()
        parameterFields.removeAll()
        
        // Actualizar título
        if let scriptName = scriptName {
            titleLabel.removeFromParent()
            titleLabel = Text(text: scriptName, fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0)
            insertChild(titleLabel, at: 0)
            
            // Obtener parámetros del script
            let parameters = scriptManager.getScriptParameters(for: scriptName)
            
            if !parameters.isEmpty {
                // Crear campos para cada parámetro
                for (name, value) in parameters {
                    // Crear el contenedor para este parámetro
                    let paramRow = HorizontalContainer(
                        spacing: 10,
                        padding: CGSize(width: 4, height: 4),
                        verticalAlignment: .center,
                        horizontalAlignment: .left,
                        showBackground: false
                    )
                    
                    // Etiqueta del parámetro
                    let paramLabel = SKLabelNode(text: "\(name):")
                    paramLabel.fontName = "HelveticaNeue"
                    paramLabel.fontSize = 12
                    paramLabel.fontColor = buttonColorText
                    paramLabel.horizontalAlignmentMode = .left
                    paramLabel.verticalAlignmentMode = .center
                    
                    // Campo de entrada
                    let inputField = InputFieldNode(text: "\(value)", width: 100, height: 24)
                    
                    // Guardar referencia al campo
                    parameterFields[name] = inputField
                    
                    // Añadir listener para cambios
                    inputField.onTextChanged = { [weak self] newValue in
                        self?.parameterChanged(name: name, value: newValue)
                    }
                    
                    // Añadir a la fila
                    paramRow.addNodes([paramLabel, inputField])
                    
                    // Añadir fila al contenedor
                    parametersContainer.addNode(paramRow)
                }
            } else {
                // Mostrar mensaje si no hay parámetros
                let noParamsLabel = SKLabelNode(text: "Script sin parámetros configurables")
                noParamsLabel.fontName = "HelveticaNeue"
                noParamsLabel.fontSize = 12
                noParamsLabel.fontColor = buttonColorText
                parametersContainer.addNode(noParamsLabel)
            }
            
            // Habilitar botones
            updateButtonsState(true)
        } else {
            // Mostrar título por defecto
            titleLabel.removeFromParent()
            titleLabel = Text(text: "Parámetros", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0)
            insertChild(titleLabel, at: 0)
            
            // Mostrar mensaje de selección
            let selectLabel = SKLabelNode(text: "Selecciona un script para ver sus parámetros")
            selectLabel.fontName = "HelveticaNeue"
            selectLabel.fontSize = 12
            selectLabel.fontColor = buttonColorText
            parametersContainer.addNode(selectLabel)
            
            // Deshabilitar botones
            updateButtonsState(false)
        }
        
        // Actualizar layout
        parametersContainer.updateLayout()
        updateLayout()
    }
    
    // Cuando cambia un parámetro
    private func parameterChanged(name: String, value: String) {
        guard let scriptName = currentScript,
              let scriptManager = scriptManager else { return }
        
        // Convertir el valor según el tipo adecuado
        let typedValue: Any
        
        if let intValue = Int(value) {
            typedValue = intValue
        } else if let doubleValue = Double(value) {
            typedValue = doubleValue
        } else if value.lowercased() == "true" {
            typedValue = true
        } else if value.lowercased() == "false" {
            typedValue = false
        } else {
            typedValue = value
        }
        
        // Actualizar el parámetro en el script
        scriptManager.updateScriptParameter(script: scriptName, parameter: name, value: typedValue)
    }
    
    // Ejecutar el script actual
    private func runScript() {
        guard let scriptName = currentScript,
              let scriptManager = scriptManager else { return }
        
        // Ejecutar el script
        if scriptManager.executeScript(named: scriptName) {
            // Efecto visual de confirmación
            let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
            runButton.run(SKAction.sequence([scaleDown, scaleUp]))
        }
    }
    
    // Abrir el script en el editor
    private func editScript() {
        guard let scriptName = currentScript,
              let scriptManager = scriptManager else { return }
        
        // Abrir el script
        scriptManager.editScript(named: scriptName)
    }
}

// Esta parte se implementará como una actualización a InputFieldNode.swift
