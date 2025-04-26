//
//  ScriptPanel.swift
//  anim-editor
//
//  Created by José Puma on 17-04-25.
//

import SpriteKit

class ScriptPanel: VerticalContainer {
    // Manejador de scripts
    private weak var scriptManager: ParticleScriptManager?
    
    // Componentes de UI
    private var scriptsSection: VerticalContainer!
    private var scriptListContainer: VerticalContainer!
    private var createScriptButton: Button!
    private var openFolderButton: Button!
    
    // Estilos
    private var accent = NSColor(red: 202 / 255, green: 217 / 255, blue: 91 / 255, alpha: 1)
    private var backgroundColorAccent = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 0.7)
    private var backgroundColorButton = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
    private var buttonColorText = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)
    
    // Script seleccionado actualmente
    private var selectedScript: String?
    
    // Callback para cuando se selecciona un script
    var onScriptSelected: ((String) -> Void)?
    
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
        
        // Cargar scripts iniciales
        refreshScriptList()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScriptsUpdated),
            name: NSNotification.Name("ScriptsListUpdated"),
            object: nil
        )

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Título principal
        let panelTitle = Text(text: "Scripts", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0)
        addNode(panelTitle)
        
        // Contenedor para la lista de scripts
        scriptsSection = VerticalContainer(
            spacing: 6,
            padding: CGSize(width: 8, height: 6),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: false
        )
        
        // Lista de scripts
        scriptListContainer = VerticalContainer(
            spacing: 4,
            padding: CGSize(width: 0, height: 0),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: false
        )
        scriptsSection.addNode(scriptListContainer)
        
        // Botones de acción
        let buttonsRow = HorizontalContainer(
            spacing: 8,
            padding: CGSize(width: 0, height: 0),
            verticalAlignment: .center,
            horizontalAlignment: .left,
            showBackground: false
        )
        
        // Botón crear nuevo script
        createScriptButton = Button(
            text: "Nuevo Script",
            padding: CGSize(width: 12, height: 8),
            buttonColor: accent,
            buttonBorderColor: accent,
            textColor: .black,
            fontSize: 12
        )
        createScriptButton.setIcon(name: "file-code-2", size: 16, color: .black)
        createScriptButton.onPress = { [weak self] in
            self?.showCreateScriptDialog()
        }
        
        // Botón abrir carpeta
        openFolderButton = Button(
            text: "Abrir Carpeta",
            padding: CGSize(width: 12, height: 8),
            buttonColor: backgroundColorButton,
            buttonBorderColor: backgroundColorButton,
            textColor: buttonColorText,
            fontSize: 12
        )
        openFolderButton.setIcon(name: "folder-open", size: 16, color: buttonColorText)
        openFolderButton.onPress = { [weak self] in
            self?.openScriptsFolder()
        }
        
        // Añadir botones a la fila
        buttonsRow.addNodes([createScriptButton, openFolderButton])
        
        // Añadir la fila al contenedor principal
        scriptsSection.addNode(buttonsRow)
        
        // Añadir todo al panel
        addNode(scriptsSection)
        
        // Separador
        addNode(Separator(width: 250, height: 1, color: backgroundColorButton))
    }
    
    func refreshScriptList() {
        guard let scriptManager = scriptManager else { return }
        
        // Limpiar la lista actual
        scriptListContainer.clearNodes()
        
        // Obtener scripts disponibles ordenados
        let scripts = scriptManager.getOrderedScripts()
        
        if scripts.isEmpty {
            // Mostrar mensaje si no hay scripts
            let emptyLabel = SKLabelNode(text: "No hay scripts disponibles")
            emptyLabel.fontName = "HelveticaNeue"
            emptyLabel.fontSize = 12
            emptyLabel.fontColor = buttonColorText
            scriptListContainer.addNode(emptyLabel)
        } else {
            // Crear un contenedor para cada script con botones para reordenar
            for script in scripts {
                // Contenedor horizontal para script y botones
                let scriptRow = HorizontalContainer(
                    spacing: 5,
                    padding: CGSize(width: 2, height: 2),
                    verticalAlignment: .center,
                    horizontalAlignment: .left,
                    showBackground: false
                )
                
                // Botones para subir/bajar
                let upButton = Button(
                    text: "↑",
                    padding: CGSize(width: 6, height: 6),
                    buttonColor: backgroundColorButton,
                    buttonBorderColor: backgroundColorButton,
                    textColor: buttonColorText,
                    fontSize: 10
                )
                
                let downButton = Button(
                    text: "↓",
                    padding: CGSize(width: 6, height: 6),
                    buttonColor: backgroundColorButton,
                    buttonBorderColor: backgroundColorButton,
                    textColor: buttonColorText,
                    fontSize: 10
                )
                
                // Configurar acciones para los botones
                upButton.onPress = { [weak self] in
                    guard let self = self, let scriptManager = self.scriptManager else { return }
                    if scriptManager.moveScriptUp(script) {
                        self.refreshScriptList()
                        scriptManager.reorderAndReexecuteScripts()
                    }
                }
                
                downButton.onPress = { [weak self] in
                    guard let self = self, let scriptManager = self.scriptManager else { return }
                    if scriptManager.moveScriptDown(script) {
                        self.refreshScriptList()
                        scriptManager.reorderAndReexecuteScripts()
                    }
                }
                
                // Botón del script
                let scriptButton = Button(
                    text: script,
                    padding: CGSize(width: 10, height: 6),
                    buttonColor: script == selectedScript ? accent : backgroundColorButton,
                    buttonBorderColor: script == selectedScript ? accent : backgroundColorButton,
                    textColor: script == selectedScript ? .black : buttonColorText,
                    fontSize: 12
                )
                
                scriptButton.onPress = { [weak self] in
                    self?.selectScript(script)
                }
                
                // Añadir componentes a la fila
                scriptRow.addNodes([upButton, downButton, scriptButton])
                
                // Añadir la fila al contenedor
                scriptListContainer.addNode(scriptRow)
            }
        }
        
        // Actualizar layout
        scriptListContainer.updateLayout()
        scriptsSection.updateLayout()
        updateLayout()
    }
    
    // Selecciona un script y notifica
    private func selectScript(_ scriptName: String) {
        // Actualizar script seleccionado
        selectedScript = scriptName
        
        // Notificar al listener
        onScriptSelected?(scriptName)
        
        // Actualizar UI
        refreshScriptList()
    }
    
    // Muestra diálogo para crear un nuevo script
    private func showCreateScriptDialog() {
        // En una implementación completa, aquí se mostraría un diálogo para elegir
        // nombre y plantilla. Por simplicidad, crearemos directamente uno basado en rain_template.
        
        guard let scriptManager = scriptManager else { return }
        
        // Generar nombre único
        let timestamp = Int(Date().timeIntervalSince1970)
        let scriptName = "custom_rain_\(timestamp)"
        
        // Crear script basado en plantilla
        if scriptManager.createNewScript(name: scriptName, fromTemplate: "rain_template") {
            refreshScriptList()
            selectScript(scriptName)
        }
    }
    
    // Abre la carpeta de scripts
    private func openScriptsFolder() {
        scriptManager?.openScriptsFolder()
    }
    
    // Ejecuta el script seleccionado
    func executeSelectedScript() -> Bool {
        guard let scriptName = selectedScript,
              let scriptManager = scriptManager else {
            return false
        }
        
        return scriptManager.executeScript(named: scriptName)
    }
    
    @objc private func handleScriptsUpdated() {
        refreshScriptList()
    }
}
