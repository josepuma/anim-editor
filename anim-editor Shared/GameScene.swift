//
//  GameScene.swift
//  anim-editor Shared
//
//  Created by José Puma on 08-08-24.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    var audioPlayer: AVAudioPlayer!
    var totalDuration: TimeInterval!
    let spriteManager = SpriteManager()
    private var spriteParser: SpriteParser!
    var barsFFT : [SKNode] = []
    var effects: [Effect] = []
    var analyzer : AudioFFTAnalyzer?
    var effectsTableNode: EffectsTableNode!
    private var timelineComponent: Timeline!
    private var gridComponent: Grid!
    private var gridToggleButton: ToggleButton!
    private var controlsContainer: VerticalContainer!
    private var toogleOptions: HorizontalContainer!
    private var volumeSlider: VolumeSlider!
    private var volumeContainer: HorizontalContainer!
    private var particleManager: ParticleManager!
    private var positionButton: Button!
    private var projectConfigManager: ProjectConfigManager?
    
    private var scriptManager: ParticleScriptManager!
    private var scriptPanel: ScriptPanel!
    private var scriptParametersPanel: ScriptParametersPanel!
    
    private var toolsContainer: VerticalContainer!
    private var currentHoveredSprite: Sprite?
    private var currentSelectedSprite: Sprite?
    
    private var accent = NSColor(red: 202 / 255, green: 217 / 255, blue: 91 / 255, alpha: 1)
    private var backgroundColorAccent = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 0.7)
    private var backgroundColorButton = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
    private var buttonColorText = NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        return scene
    }
    
    let path = "/Users/josepuma/Documents/storyboards/freda-maybe/"
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .black
        projectConfigManager = ProjectConfigManager(projectPath: path)
        IconManager.shared.preloadAllIcons(colors: [.white, .green, .blue])

        let trackingArea = NSTrackingArea(
            rect: view.visibleRect,  // Usa visibleRect en lugar de bounds
            options: [.activeAlways, .mouseMoved, .enabledDuringMouseDrag, .inVisibleRect],
            owner: view,
            userInfo: nil
        )
        
        // Elimina áreas de seguimiento existentes y añade la nueva
        view.trackingAreas.forEach { view.removeTrackingArea($0) }
        view.addTrackingArea(trackingArea)

        let audioFilePath = path + "audio.mp3"
        setupAudio(filePath: audioFilePath)
        spriteManager.addToScene(scene: self)
        
        
        setupGrid()
        setupControls()

        setupScriptSystem()
        setupScriptButtons()

        if let preferences = projectConfigManager?.getPreferences() {
           // Aplicar preferencias
           if let player = audioPlayer {
               player.volume = Float(preferences.defaultVolume)
               volumeSlider?.setVolume(CGFloat(preferences.defaultVolume), animated: false)
           }
           
           // Configurar grid
           gridToggleButton.setState(isToggled: preferences.defaultGridVisible)
           toggleGridVisibility(visible: preferences.defaultGridVisible)
       }
        
        projectConfigManager?.updatePreference(key: "lastOpenedTime", value: Date())
    }
    
    func updateProjectPreference<T>(key: String, value: T) {
        projectConfigManager?.updatePreference(key: key, value: value)
    }
    
    func setupTimeline() {
        // Inicializar los iconos de reproducción
        
        let width = size.width * 0.8 // 90% del ancho de la pantalla
        timelineComponent = Timeline(width: width)
        
        // Posicionar en la parte inferior, considerando que (0,0) es el centro
        let bottomPadding: CGFloat = 40
        timelineComponent.position = CGPoint(
            x: 0, // Centrado horizontalmente
            y: -size.height/2 + bottomPadding // Parte inferior + padding
        )
        
        timelineComponent.zPosition = 100
        addChild(timelineComponent)
        
        if let player = audioPlayer {
            timelineComponent.setAudioPlayer(player)
            
            // Configurar callback para manejar cambios de tiempo
            timelineComponent.onTimeChange = { [weak self] newTime in
                // Puedes realizar acciones adicionales cuando el usuario cambia la posición
                // Por ejemplo, actualizar la posición de los sprites
                if let self = self, let player = self.audioPlayer {
                    let gameTime = Int(player.currentTime * 1000)
                    self.spriteManager.updateAll(currentTime: gameTime)
                }
            }
        }
    }
    
    func setupTimelineWithPreview() {
        // Configurar el timeline (ya existente)
        setupTimeline()
        
        // Configurar el callback para generar vistas previas
        timelineComponent.onRequestPreview = { [weak self] (timeMilliseconds, completion) in
            guard let self = self else { return }
            
            // Usar el SpriteManager existente para obtener una textura en el tiempo solicitado
            // Primero, crear una copia del tamaño para la vista previa (más pequeño)
            let previewSize = CGSize(width: 256, height: 144)
            
            // Generar la textura usando el método existente en SpriteManager
            self.spriteManager.textureForTime(time: timeMilliseconds, size: previewSize) { texture in
                // Completar con la textura generada
                completion(texture)
            }
        }
    }
    
    func setupScriptSystem() {
        // Asegurarse de que existe la carpeta de scripts
        let scriptsFolder = path + "/scripts"
        
        // Crear el administrador de scripts
        scriptManager = ParticleScriptManager(
            particleManager: particleManager,
            scene: self,
            scriptsFolder: scriptsFolder
        )
        
        // Crear el panel de scripts
        scriptPanel = ScriptPanel(scriptManager: scriptManager)
        scriptPanel.zPosition = 100
        addChild(scriptPanel)
        
        // Configurar callback para selección de script
        scriptPanel.onScriptSelected = { [weak self] scriptName in
            self?.scriptParametersPanel.updateWithScript(scriptName)
        }
        
        // Crear el panel de parámetros
        scriptParametersPanel = ScriptParametersPanel(scriptManager: scriptManager)
        scriptParametersPanel.setScriptPanel(scriptPanel)
        scriptParametersPanel.zPosition = 100
        addChild(scriptParametersPanel)
        
        // Inicializar sin script seleccionado
        scriptParametersPanel.updateWithScript(nil)
    }
    
    func setupControls() {
        particleManager = ParticleManager(
            spriteManager: spriteManager,
            scene: self,
            texturesPath: path // Asumiendo que tienes una variable 'path' como ruta base
        )
        
        effectsTableNode = EffectsTableNode()
        effectsTableNode.spriteManager = spriteManager
        effectsTableNode.parentScene = self
        effectsTableNode.zPosition = 111111
        effectsTableNode.position = CGPoint(x: self.size.width/2 , y: 0)
        
        
        toolsContainer = VerticalContainer(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .center,
            horizontalAlignment: .left,
            showBackground: true,
            backgroundColor: NSColor(red: 7 / 255, green: 7 / 255, blue: 13 / 255, alpha: 1),
            cornerRadius: 8
        )
        
        volumeSlider = VolumeSlider(width: 150, height: 4, knobSize: 12)
        
        volumeSlider.onVolumeChange = { [weak self] volume in
            self?.audioPlayer?.volume = Float(volume)
        }
        
        // Si ya hay un reproductor de audio, establecer el volumen inicial
        if let player = audioPlayer {
            volumeSlider.setVolume(CGFloat(player.volume), animated: false)
        } else {
            volumeSlider.setVolume(0.5, animated: false) // Valor predeterminado
        }
        
        let volumeIcon = IconManager.shared.getIcon(named: "volume", size: 16, color: NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1))
            
        // Crear el contenedor horizontal
        volumeContainer = HorizontalContainer(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .center,
            horizontalAlignment: .left,
            showBackground: true,
            backgroundColor: NSColor(red: 7 / 255, green: 7 / 255, blue: 13 / 255, alpha: 1),
            cornerRadius: 8
        )
        
        volumeContainer.addNodes([volumeIcon, volumeSlider])
        
        // Crear el contenedor
        controlsContainer = VerticalContainer(
            spacing: 10,
            padding: CGSize(width: 8, height: 8),
            verticalAlignment: .top,
            horizontalAlignment: .left,
            showBackground: true,
            backgroundColor: NSColor(red: 7 / 255, green: 7 / 255, blue: 13 / 255, alpha: 1),
            cornerRadius: 8
        )
        
        // Crear los botones
        gridToggleButton = ToggleButton(
            size: 32,
            onIconName: "eye-dotted",
            offIconName: "eye-closed",
            isInitiallyToggled: false,
            buttonColor: .clear,
            buttonBorderColor: .clear,
            iconColor: NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)
        )
        
        //button background color NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
        
        // Configurar el callback
        gridToggleButton.onToggle = { [weak self] isVisible in
            self?.toggleGridVisibility(visible: isVisible)
        }
        
        let toggleScriptsButton = ToggleButton(
            size: 32,
            onIconName: "file-code-2",
            offIconName: "file-code-2",
            isInitiallyToggled: false,
            buttonColor: .clear,
            buttonBorderColor: .clear,
            iconColor: NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)
        )
        
        // Configurar callback
        toggleScriptsButton.onToggle = { [weak self] isVisible in
            self?.toggleScriptPanelsVisibility(visible: isVisible)
        }

        let openFolderButton = Button(text: "Open Project Folder", padding: CGSize(width: 20, height: 8), buttonColor: accent, buttonBorderColor: accent, textColor: .black, fontSize: 12)
        openFolderButton.setIcon(name: "folder-open", size: 16, color: .black)
        
        let openScriptButton = Button(text: "Open Scripts Folder", padding: CGSize(width: 20, height: 8), buttonColor: accent, buttonBorderColor: accent, textColor: .black, fontSize: 12)
        openScriptButton.setIcon(name: "folder-open", size: 16, color: .black)
        
        let createNewScriptButton = Button(text: "Open Scripts Folder", padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12)
        
        positionButton = Button(text: "X: 320 - Y: 240", padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: accent, fontSize: 12)
        positionButton.setIcon(name: "grid-4x4", size: 16, color: accent)
        
        let createScriptButton = Button(text: "New Script", padding: CGSize(width: 20, height: 8), buttonColor: accent, buttonBorderColor: accent, textColor: .black, fontSize: 12)
        createScriptButton.setIcon(name: "file-code-2", size: 16, color: .black)
        
        openFolderButton.onPress = {
            let url = URL(fileURLWithPath: self.path)
            NSWorkspace.shared.open(url)
        }
        
        let gridOptions = HorizontalContainer(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .center,
            horizontalAlignment: .left,
            showBackground: false
        )
        
        toogleOptions = HorizontalContainer(
            spacing: 10,
            padding: CGSize(width: 10, height: 8),
            verticalAlignment: .center,
            horizontalAlignment: .left,
            showBackground: false
        )
        
        toogleOptions.addNodes([
            gridToggleButton,
            ToggleButton(size: 32, onIconName: "camera", offIconName: "camera", buttonColor: .clear, buttonBorderColor: .clear, iconColor: NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)),
            ToggleButton(size: 32, onIconName: "zoom-code", offIconName: "zoom-code", buttonColor: .clear, buttonBorderColor: .clear, iconColor: NSColor(red: 195 / 255, green: 195 / 255, blue: 208 / 255, alpha: 1)),
            toggleScriptsButton
        ])
        
        gridOptions.addNodes([
            Button(text: "1:1", padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
            Button(text: "16:9", padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
            Button(text: "5:4", padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12)
        ])
        
        toolsContainer.addNodes([
            Text(text: "Audio", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0),
            volumeContainer,
            Separator(),
            Text(text: "Editor", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0),
            toogleOptions,
            positionButton,
            Separator(),
            Text(text: "CODING", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0),
            gridOptions,
            createScriptButton,
            Button(text: "Open Scripts Folder", padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
            Separator(),
            Text(text: "System", fontSize: 10, color: backgroundColorAccent, type: .capitalTitle, letterSpacing: 2.0),
            Button(text: "Open Project Folder", padding: CGSize(width: 20, height: 8), buttonColor: backgroundColorButton, buttonBorderColor: backgroundColorButton, textColor: buttonColorText, fontSize: 12),
            createNewScriptButton,
        ])

        toolsContainer.zPosition = 100
        addChild(toolsContainer)
        
    }

    
    func toggleGridVisibility(visible: Bool) {
        guard let gridComponent = gridComponent else { return }
        
        if visible {
            // Mostrar grid con animación de fade in
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            gridComponent.run(fadeIn)
        } else {
            // Ocultar grid con animación de fade out
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            gridComponent.run(fadeOut)
        }
    }
    
    func setupGrid() {
        gridComponent = Grid(cellSize: 20) // Ajusta el tamaño de celda según prefieras
        gridComponent.position = CGPoint.zero // Centrado en la escena
        gridComponent.zPosition = 5 // Por debajo de la UI pero por encima del fondo
        gridComponent.alpha = 0.0
        addChild(gridComponent)
        
        // Ajustar al tamaño de la pantalla
        gridComponent.adjustForScreenSize(screenSize: self.size)
        
        gridComponent.onMousePositionChange = {value in
            self.positionButton.setText(text: value)
        }
    }
    
    func addEffect(_ effect: Effect) {
        effects.append(effect)
        effect.apply(to: spriteManager, in: self)
        effectsTableNode.effects = effects
        effectsTableNode.reloadData()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
       super.didChangeSize(oldSize)
        
        if gridComponent != nil {
            gridComponent.adjustForScreenSize(screenSize: self.size)
        }
        
        if timelineComponent != nil {
            timelineComponent.adjustForScreenSize(width: size.width, height: size.height)
            
            // Reposicionar el timeline en la parte inferior
            // En SpriteKit, Y negativo significa la parte inferior
            let bottomPadding: CGFloat = 40 // Píxeles desde el borde inferior
            timelineComponent.position = CGPoint(
                x: 0, // Centrado horizontalmente
                y: -size.height/2 + bottomPadding // Parte inferior + padding
            )
        }
        
        let margin: CGFloat = 16
        if toolsContainer != nil {
            toolsContainer.position = CGPoint(
                x: self.size.width/2 - margin - toolsContainer.getSize().width/2,
                y: self.size.height/2 - margin - toolsContainer.getSize().height/2
            )
        }
        
        if scriptPanel != nil {
            scriptPanel.position = CGPoint(
                x: -self.size.width/2 + 16 + scriptPanel.getSize().width/2,
                y: self.size.height/2 - 16 - scriptPanel.getSize().height/2
            )
            if let parametersPanel = scriptParametersPanel {
                parametersPanel.updatePositionRelativeToScriptPanel()
            }
        }
        
        // Posicionar panel de parámetros
        /*if scriptParametersPanel != nil {
            let parametersMargin = 10 // Espacio entre paneles
            let scriptPanelRightEdge = -self.size.width/2 + 16 + scriptPanel.getSize().width
            let parametersPanelX = scriptPanelRightEdge + CGFloat(parametersMargin) + scriptParametersPanel.getSize().width/2
            let parametersPanelY = self.size.height/2 - 16 - scriptParametersPanel.getSize().height/2
            scriptParametersPanel.position = CGPoint(x: parametersPanelX, y: parametersPanelY)
        }*/
       
        spriteManager.updateSize()
        if let scriptManager = scriptManager {
            let newScale = spriteManager.getScale() // Asumiendo que añadimos este getter
            
            // Actualizar todas las escenas de scripts
            for (_, scriptScene) in scriptManager.getScriptScenes() {
                scriptScene.setContentScale(newScale)
            }
        }
   }
    
    func setupScriptButtons() {
    }
    
    func toggleScriptPanelsVisibility(visible: Bool) {
        guard scriptPanel != nil && scriptParametersPanel != nil else { return }
        
        if visible {
            // Mostrar paneles con animación
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            scriptPanel.run(fadeIn)
            scriptParametersPanel.run(fadeIn)
        } else {
            // Ocultar paneles con animación
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            scriptPanel.run(fadeOut)
            scriptParametersPanel.run(fadeOut)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if audioPlayer != nil{
            let gameTime = Int(audioPlayer.currentTime * 1000) // Convert to milliseconds or your desired unit
            
            if let scriptManager = scriptManager {
                for (_, scriptScene) in scriptManager.getScriptScenes() {
                    scriptScene.update(atTime: gameTime)
                }
            }
            
            if let hoveredSprite = currentHoveredSprite {
                if hoveredSprite.isActive(at: gameTime) {
                    hoveredSprite.updateHoverBorder()
                } else {
                    hoveredSprite.removeHoverBorder()
                    currentHoveredSprite = nil
                }
            }
            
            if let selectedSprite = currentSelectedSprite {
                if selectedSprite.isActive(at: gameTime) {
                    selectedSprite.updateBorders()
                } else {
                    selectedSprite.removeSelectionBorder()
                    currentSelectedSprite = nil
            
                }
            }
        }
    }
    
    func setupAudio(filePath: String) {
        let url = URL(fileURLWithPath: filePath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            totalDuration = audioPlayer.duration
            // Cambiar esto para no establecer volumen a 0
            audioPlayer.volume = 0.5 // Volumen predeterminado al 50%
            audioPlayer.play()
            // Configurar el timeline después de inicializar el audio
            setupTimelineWithPreview()
            timelineComponent.updatePlayPauseButton(isPlaying: true)
            
            // Si el control de volumen ya se inicializó, actualizar su valor
            volumeSlider?.setVolume(CGFloat(audioPlayer.volume), animated: false)
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
    func togglePlayPause() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
            } else {
                player.play()
            }
            
            timelineComponent.updatePlayPauseButton(isPlaying: player.isPlaying)
        }
    }
    
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        //self.atPoint(event.location(in: self)).mouseDown(with: event)
        super.mouseDown(with: event)
        
        // Manejar selección de sprite
           let location = event.location(in: self)
           let nodesAtPoint = nodes(at: location)
           
           var selectedSprite: Sprite? = nil
           for node in nodesAtPoint {
               if node is SKSpriteNode || node.parent is SKSpriteNode {
                   if let sprite = spriteManager.getSpriteForNode(node) {
                       if sprite.isActive(at: Int((audioPlayer?.currentTime ?? 0) * 1000)) {
                           selectedSprite = sprite
                           break
                       }
                   }
               }
           }
           
           // Primero, desmarcar el sprite anterior si existe
           if let currentSprite = currentSelectedSprite {
               currentSprite.setSelected(false)
               currentSprite.removeSelectionBorder() // Eliminar explícitamente el borde
           }
           
           // Actualizar la referencia al sprite seleccionado
           currentSelectedSprite = selectedSprite
           
           // Si hay un nuevo sprite seleccionado
           if let sprite = selectedSprite {
               // Marcar como seleccionado
               sprite.setSelected(true)
               // Mostrar y actualizar panel de información

           } else {
               // Ocultar panel si no hay selección

           }
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.atPoint(event.location(in: self)).mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.atPoint(event.location(in: self)).mouseUp(with: event)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let location = event.location(in: self)
        let nodesAtPoint = nodes(at: location)
        
        // Pasar el evento al componente de grid
        if let gridComponent = gridComponent {
            let location = event.location(in: self)
            gridComponent.handleMouseMovement(location: location)
        }
        
        if let timeline = timelineComponent {
            timeline.mouseMoved(with: event)
        }
        
        var foundSprite: Sprite? = nil
        for node in nodesAtPoint {
            // Verificar primero si es un SKSpriteNode o si su padre es un SKSpriteNode
            if node is SKSpriteNode || node.parent is SKSpriteNode {
                if let sprite = spriteManager.getSpriteForNode(node) {
                    if sprite.isActive(at: Int((audioPlayer?.currentTime ?? 0) * 1000)) {
                        foundSprite = sprite
                        break
                    }
                }
            }
        }

        if foundSprite !== currentHoveredSprite {
            currentHoveredSprite?.removeHoverBorder()
            foundSprite?.setHovered(true)  // Solo marcamos como hover
            currentHoveredSprite = foundSprite
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        // También propagar el evento mouseExited
        if let timeline = timelineComponent {
            timeline.mouseExited(with: event)
        }
    }
    
    override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case 123: // Flecha izquierda
                // Retroceder 5 segundos
                if let player = audioPlayer {
                    let newTime = max(0, player.currentTime - 5)
                    player.currentTime = newTime
                }
            case 124: // Flecha derecha
                // Adelantar 5 segundos
                if let player = audioPlayer {
                    let newTime = min(player.duration, player.currentTime + 5)
                    player.currentTime = newTime
                }
            case 49:
                if let player = audioPlayer {
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                    timelineComponent.updatePlayPauseButton(isPlaying: player.isPlaying)
                    }
            default:
                super.keyDown(with: event)
            }
        }

}

extension SKView {
    override open func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        // Pasa el evento a la escena actual
        if let scene = scene as? GameScene {
            scene.mouseMoved(with: event)
        }
    }
    
    override open func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        // Pasar el evento mouseExited también
        if let scene = scene as? GameScene {
            scene.mouseExited(with: event)
        }
    }
}
#endif

