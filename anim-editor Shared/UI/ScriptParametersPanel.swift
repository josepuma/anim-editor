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
    private weak var scriptPanel: SKNode?
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
    
    // Mapeo de controles a sus parámetros
    private var parameterFields: [String: InputFieldNode] = [:]
    private var parameterToggles: [String: ToggleButton] = [:]
    
    init(scriptManager: ParticleScriptManager) {
        // Inicializar con el mismo estilo que otros contenedores
        super.init(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: true,
            backgroundColor: NSColor(red: 7 / 255, green: 7 / 255, blue: 13 / 255, alpha: 1),
            cornerRadius: 0
        )
        
        self.scriptManager = scriptManager
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setScriptPanel(_ panel: SKNode) {
        self.scriptPanel = panel
    }
    
    private func setupUI() {
        // Contenedor de parámetros
        parametersContainer = VerticalContainer(
            spacing: 8,
            padding: CGSize(width: 0, height: 0),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: false
        )
        addNode(parametersContainer)
    }
    
    // Actualizar para mostrar parámetros de un nuevo script
    func updateWithScript(_ scriptName: String?) {
        guard let scriptManager = scriptManager else { return }
        
        // Actualizar script actual
        currentScript = scriptName
        
        // Limpiar la vista
        parametersContainer.clearNodes()
        parameterFields.removeAll()
        parameterToggles.removeAll()
        
        // Actualizar título
        if let scriptName = scriptName {
            // Obtener parámetros del script
            let parameters = scriptManager.getScriptParameters(for: scriptName)
            
            print(parameters)
            
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
                    
                    let paramLabel = Text(text: name, fontSize: 14, color: buttonColorText, type: .paragraph, letterSpacing: -2, width: 100)
                    
                    // Verificar el tipo del valor
                    if type(of: value) == Bool.self, let boolValue = value as? Bool {
                        // Para valores booleanos, usar ToggleButton
                        let toggleButton = ToggleButton(
                            size: 32,
                            onIconName: "square-check",
                            offIconName: "square-dashed",
                            isInitiallyToggled: boolValue,
                            buttonColor: .clear,
                            buttonBorderColor: .clear,
                            iconColor: accent
                        )
                        
                        // Guardar referencia al toggle
                        parameterToggles[name] = toggleButton
                        
                        // Añadir listener para cambios
                        toggleButton.onToggle = { [weak self] isToggled in
                            self?.parameterChanged(name: name, value: isToggled)
                        }
                        
                        // Añadir a la fila
                        paramRow.addNodes([paramLabel, toggleButton])
                    } else {
                        // Para otros tipos, usar InputFieldNode
                        let inputField = InputFieldNode(text: "\(value)", width: 100, height: 24)
                        
                        // Guardar referencia al campo
                        parameterFields[name] = inputField
                        
                        // Añadir listener para cambios
                        inputField.onTextChanged = { [weak self] newValue in
                            self?.parameterChanged(name: name, value: newValue)
                        }
                        
                        // Añadir a la fila
                        paramRow.addNodes([paramLabel, inputField])
                    }
                    
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
        } else {
            // Mostrar mensaje de selección
            let selectScriptLabel = SKLabelNode(text: "Selecciona un script para ver sus parámetros")
            selectScriptLabel.fontName = "HelveticaNeue"
            selectScriptLabel.fontSize = 12
            selectScriptLabel.fontColor = buttonColorText
            parametersContainer.addNode(selectScriptLabel)
        }
        
        // Actualizar layout
        parametersContainer.updateLayout()
        updateLayout()
        
        updatePositionRelativeToScriptPanel()
    }
    
    func updatePositionRelativeToScriptPanel() {
        guard let scriptPanel = scriptPanel else { return }
        
        // Asegurar que el layout esté actualizado primero
        updateLayout()
        
        // Margen entre paneles
        let parametersMargin: CGFloat = 0
        
        // Obtener dimensiones de ambos paneles
        let scriptPanelFrame = scriptPanel.calculateAccumulatedFrame()
        let thisFrame = self.calculateAccumulatedFrame()
        
        // Calcular nueva posición X (igual que antes)
        let newX = scriptPanel.position.x + scriptPanelFrame.width/2 + parametersMargin + thisFrame.width/2
        
        // Calcular posición Y para alinear los bordes superiores
        // 1. Encontrar el borde superior del script panel en relación a su centro
        let scriptPanelTopEdgeOffset = scriptPanelFrame.height/2
        // 2. Encontrar el borde superior de este panel en relación a su centro
        let thisTopEdgeOffset = thisFrame.height/2
        // 3. Calcular la diferencia para alinear los bordes superiores
        let topAlignmentDifference = scriptPanelTopEdgeOffset - thisTopEdgeOffset
        // 4. La nueva posición Y será la posición Y del scriptPanel más la diferencia
        let newY = scriptPanel.position.y + topAlignmentDifference
        
        // Actualizar posición
        self.position = CGPoint(x: newX, y: newY)
    }
    
    // Cuando cambia un parámetro
    private func parameterChanged(name: String, value: Any) {
        guard let scriptName = currentScript,
              let scriptManager = scriptManager else {
            return
        }
        
        // Convertir valores de texto según sea necesario
        let typedValue: Any
        
        if let boolValue = value as? Bool {
            // Los valores booleanos ya vienen correctamente tipados del toggle
            typedValue = boolValue
        } else if let stringValue = value as? String {
            // Para valores de texto, intentar convertir a tipos numéricos
            if let intValue = Int(stringValue) {
                typedValue = intValue
            } else if let doubleValue = Double(stringValue) {
                typedValue = doubleValue
            } else {
                // Si no se puede convertir a número, mantener como string
                typedValue = stringValue
            }
        } else {
            // Para otros tipos, usar el valor tal cual
            typedValue = value
        }
        
        // Actualizar el parámetro en el script
        scriptManager.updateScriptParameter(script: scriptName, parameter: name, value: typedValue)
    }
}
