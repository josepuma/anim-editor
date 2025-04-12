//
//  Timeline.swift
//  anim-editor
//
//  Created by José Puma on 12-04-25.
//

import SpriteKit
import AVFoundation

class Timeline: SKNode {
    // UI Elements
    private var backgroundBar: SKShapeNode!
    private var progressBar: SKShapeNode!
    private var timeLabel: SKLabelNode!
    private var durationLabel: SKLabelNode!
    private var playButton: SKLabelNode!
    private var hitboxNode: SKShapeNode!
    
    // Properties
    private var barWidth: CGFloat
    private var barHeight: CGFloat
    private var cornerRadius: CGFloat
    
    // Audio relacionado
    private var audioPlayer: AVAudioPlayer?
    private var isDragging = false
    private var updateTimer: Timer?
    
    // Callback para notificar cambios en la posición
    var onTimeChange: ((TimeInterval) -> Void)?
    
    init(width: CGFloat, height: CGFloat = 8, cornerRadius: CGFloat = 4) {
        self.barWidth = width
        self.barHeight = height
        self.cornerRadius = cornerRadius
        
        super.init()
        
        setupUI()
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Background bar (gray)
        backgroundBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: cornerRadius)
        backgroundBar.fillColor = .darkGray
        backgroundBar.strokeColor = .clear
        backgroundBar.alpha = 0.2
        addChild(backgroundBar)
        
        // Progress bar (white)
        progressBar = SKShapeNode()
        let initialRect = CGRect(x: -barWidth/2, y: -barHeight/2, width: 0, height: barHeight)
        progressBar.path = CGPath(roundedRect: initialRect,
                                 cornerWidth: cornerRadius,
                                 cornerHeight: cornerRadius,
                                 transform: nil)
        progressBar.fillColor = .white
        progressBar.strokeColor = .clear
        // No cambiar la posición, debe estar en (0,0) relativo al padre
        addChild(progressBar)
        
        // Current time label
        timeLabel = SKLabelNode(text: "0:00")
        timeLabel.fontName = "HelveticaNeue-Medium"
        timeLabel.fontSize = 12
        timeLabel.fontColor = .white
        timeLabel.position = CGPoint(x: -barWidth/2, y: -barHeight - 8)
        timeLabel.horizontalAlignmentMode = .left
        addChild(timeLabel)
        
        // Duration label
        durationLabel = SKLabelNode(text: "0:00")
        durationLabel.fontName = "HelveticaNeue-Medium"
        durationLabel.fontSize = 12
        durationLabel.fontColor = .white
        durationLabel.position = CGPoint(x: barWidth/2, y: -barHeight - 8)
        durationLabel.horizontalAlignmentMode = .right
        addChild(durationLabel)
        
        // Play button (optional)
        playButton = SKLabelNode(text: "▶")  // Símbolo Unicode de reproducción
        playButton.fontName = "HelveticaNeue-Bold"
        playButton.fontSize = 18
        playButton.fontColor = .white
        playButton.position = CGPoint(x: -barWidth/2 - 32, y: 0)
        playButton.horizontalAlignmentMode = .center
        playButton.verticalAlignmentMode = .center
        playButton.name = "playButton"
        addChild(playButton)
        
        let hitboxHeight: CGFloat = barHeight * 4 // Área de detección 4 veces más alta que la barra
        hitboxNode = SKShapeNode(rectOf: CGSize(width: barWidth, height: hitboxHeight), cornerRadius: cornerRadius)
        hitboxNode.fillColor = .clear // Invisible
        hitboxNode.strokeColor = .clear
        hitboxNode.alpha = 1 // Casi invisible, pero detectable
        hitboxNode.name = "progressHitbox"
        addChild(hitboxNode)
    }
    
    func setAudioPlayer(_ player: AVAudioPlayer) {
        self.audioPlayer = player
        updateDurationLabel(player.duration)
        
        // Iniciar timer de actualización
        startUpdateTimer()
    }
    
    private func startUpdateTimer() {
        // Cancelar timer existente si hay uno
        updateTimer?.invalidate()
        
        // Crear nuevo timer que actualiza la posición cada 1/10 segundo
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgressDisplay()
        }
    }
    
    private func updateProgressDisplay() {
        guard let player = audioPlayer, !isDragging else { return }
        
        let progress = CGFloat(player.currentTime / player.duration)
        let progressWidth = barWidth * progress
        
        // Importante: Mantener la posición X igual que la barra de fondo
        // pero ajustar el ancho según el progreso
        let progressRect = CGRect(
            x: -barWidth/2, // Mismo X que la barra de fondo
            y: -barHeight/2,
            width: progressWidth,
            height: barHeight
        )
        
        progressBar.path = CGPath(roundedRect: progressRect,
                                 cornerWidth: cornerRadius,
                                 cornerHeight: cornerRadius,
                                 transform: nil)
        
        updateTimeLabel(player.currentTime)
    }
    
    private func updateTimeLabel(_ time: TimeInterval) {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        timeLabel.text = String(format: "%d:%02d", minutes, seconds)
    }
    
    private func updateDurationLabel(_ duration: TimeInterval) {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        durationLabel.text = String(format: "%d:%02d", minutes, seconds)
    }
    
    // Manejo de interacciones
    
    private func updateProgressFromTouch(_ touchLocation: CGPoint) {
        guard let player = audioPlayer else { return }
        
        // Calcular la posición relativa del toque en la barra
        // La barra va desde -barWidth/2 hasta +barWidth/2
        let touchRelativeX = touchLocation.x + barWidth/2
        let cappedTouchX = max(0, min(touchRelativeX, barWidth))
        let progress = cappedTouchX / barWidth
        
        // Actualizar la posición de reproducción del audio
        let newTime = player.duration * Double(progress)
        player.currentTime = newTime
        
        // Actualizar la visualización de la barra de progreso
        let progressWidth = barWidth * progress
        let progressRect = CGRect(
            x: -barWidth/2, // Siempre comienza desde el extremo izquierdo
            y: -barHeight/2,
            width: progressWidth,
            height: barHeight
        )
        
        // Actualizar el path de la barra de progreso
        progressBar.path = CGPath(roundedRect: progressRect,
                                 cornerWidth: cornerRadius,
                                 cornerHeight: cornerRadius,
                                 transform: nil)
        
        // Actualizar la etiqueta de tiempo
        updateTimeLabel(newTime)
        
        // Notificar el cambio
        onTimeChange?(newTime)
    }
    
    private func togglePlayPause() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            playButton.text = "▶"  // Símbolo Unicode de reproducción
        } else {
            player.play()
            playButton.text = "⏸"  // Símbolo Unicode de pausa
        }
    }
    
    // También podemos actualizar manualmente el estado de reproducción
    func updatePlayPauseButton(isPlaying: Bool) {
        playButton.text = isPlaying ? "⏸" : "▶"  // Símbolos Unicode para pausa y reproducción
    }
    
    func adjustForScreenSize(width: CGFloat, height: CGFloat) {
        // Ajustar ancho a 90% de la pantalla
        barWidth = width * 0.9
        
        // Actualizar barra de fondo
        backgroundBar.path = CGPath(roundedRect: CGRect(x: -barWidth/2, y: -barHeight/2, width: barWidth, height: barHeight),
                                   cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        
        // Recalcular progreso
        if let player = audioPlayer {
            updateProgressDisplay()
        }
        
        // Reubicar etiquetas
        timeLabel.position = CGPoint(x: -barWidth/2, y: -barHeight - 8)
        durationLabel.position = CGPoint(x: barWidth/2, y: -barHeight - 8)
        
        // Aumentar el padding horizontal para el botón de reproducción
        let buttonPadding: CGFloat = 20 // Aumentar este valor según necesites
        playButton.position = CGPoint(x: -barWidth/2 - buttonPadding, y: 0)
        
        // Actualizar el hitbox
        let hitboxHeight: CGFloat = barHeight * 4
        hitboxNode.path = CGPath(roundedRect: CGRect(x: -barWidth/2, y: -hitboxHeight/2, width: barWidth, height: hitboxHeight),
                                cornerWidth: cornerRadius,
                                cornerHeight: cornerRadius,
                                transform: nil)
    }
    
    // Para macOS
    #if os(OSX)
    override func mouseDown(with event: NSEvent) {
        let touchLocation = event.location(in: self)
        
        if hitboxNode.contains(touchLocation) {
            // El usuario tocó dentro del área ampliada
            isDragging = true
            updateProgressFromTouch(touchLocation)
        } else if playButton.contains(touchLocation) {
            togglePlayPause()
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if isDragging {
            let touchLocation = event.location(in: self)
            updateProgressFromTouch(touchLocation)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if isDragging {
            isDragging = false
        }
    }
    #endif
}
