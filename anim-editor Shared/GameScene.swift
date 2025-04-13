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
    private var gridToggleButton: GridToggleButton!
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        return scene
    }
    
    let path = "/Users/josepuma/Downloads/1151309 Stonebank - Be Alright (feat. EMEL) (Cut Ver.)/"
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .black
        
            
            // Crea un NSTrackingArea que abarque toda la vista
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
 
        spriteParser = SpriteParser(spriteManager: spriteManager, filePath: path + "Stonebank - Be Alright (feat. EMEL) (Cut Ver.) (Nhawak).osb")
        spriteParser.parseSprites()
        spriteManager.addToScene(scene: self)
        
        
        setupGrid()
        setupGridToggleButton()
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
    
    func setupGridToggleButton() {
        gridToggleButton = GridToggleButton(size: 32)
        
        // Posicionar en la esquina superior derecha
        let margin: CGFloat = 20
        gridToggleButton.position = CGPoint(
            x: self.size.width/2 - margin - 16,
            y: self.size.height/2 - margin - 16
        )
        
        // Configurar el callback
        gridToggleButton.onToggle = { [weak self] isVisible in
            self?.toggleGridVisibility(visible: isVisible)
        }
        
        gridToggleButton.zPosition = 100 // Asegura que esté por encima del grid
        addChild(gridToggleButton)
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
        
        if gridToggleButton != nil {
            let margin: CGFloat = 20
            gridToggleButton.position = CGPoint(
                x: self.size.width/2 - margin - 16,
                y: self.size.height/2 - margin - 16
            )
        }
        
        updateContainerLayouts()
        spriteManager.updateSize()
   }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if audioPlayer != nil{
            let gameTime = Int(audioPlayer.currentTime * 1000) // Convert to milliseconds or your desired unit
            spriteManager.updateAll(currentTime: gameTime)
        }
    }
    
    func setupAudio(filePath: String) {
        let url = URL(fileURLWithPath: filePath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            totalDuration = audioPlayer.duration
            audioPlayer.volume = 0
            audioPlayer.play()
            // Configurar el timeline después de inicializar el audio
            setupTimelineWithPreview()
            timelineComponent.updatePlayPauseButton(isPlaying: true)
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
        self.atPoint(event.location(in: self)).mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.atPoint(event.location(in: self)).mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.atPoint(event.location(in: self)).mouseUp(with: event)
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        // Pasar el evento al componente de grid
        if let gridComponent = gridComponent {
            let location = event.location(in: self)
            gridComponent.handleMouseMovement(location: location)
        }
        
        if let timeline = timelineComponent {
            timeline.mouseMoved(with: event)
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

