//
//  TimelinePreviewNode.swift
//  anim-editor
//
//  Created by José Puma on 12-04-25.
//

import SpriteKit

class TimelinePreviewNode: SKNode {
    // UI Elements
    private var previewNode: SKSpriteNode!
    private var loadingIndicator: SKShapeNode!
    
    // Propiedades de apariencia
    private let width: CGFloat = 256
    private let height: CGFloat = 144
    private let cornerRadius: CGFloat = 8
    private let borderWidth: CGFloat = 1
    
    // Estado interno
    private var isLoading = false
    private var currentTime: Int = 0
    
    override init() {
        super.init()
        setupUI()
        isUserInteractionEnabled = false
        alpha = 0 // Inicialmente invisible
        zPosition = 110 // Por encima de otros elementos
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        // El nodo de vista previa debe ocupar TODO el espacio disponible
        previewNode = SKSpriteNode(color: .clear, size: CGSize(width: width, height: height))
        previewNode.position = CGPoint.zero  // Centrado
        previewNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)  // Ancla en el centro
        addChild(previewNode)
        
        // Indicador de carga
        loadingIndicator = SKShapeNode(circleOfRadius: 15)
        loadingIndicator.strokeColor = .white
        loadingIndicator.lineWidth = 2
        loadingIndicator.fillColor = .clear
        loadingIndicator.position = CGPoint(x: 0, y: 0)
        loadingIndicator.isHidden = true
        loadingIndicator.zPosition = 1 // También por encima
        addChild(loadingIndicator)
    }
    
    func show(at position: CGPoint) {

        
        if let scene = self.scene {
            let sceneSize = scene.size
            
            // Posicionar en X según cursor, en Y según posición fija del timeline
            self.position = CGPoint(
                x: position.x,
                y: -scene.position.y + 90
            )
            
            // Ajustar horizontalmente para no salirse de los límites
            if self.position.x - width/2 < -sceneSize.width/2 {
                self.position.x = -sceneSize.width/2 + width/2 + 10
            } else if self.position.x + width/2 > sceneSize.width/2 {
                self.position.x = sceneSize.width/2 - width/2 - 10
            }
        }
        
        // Mostrar con animación de fade in
        self.removeAllActions()
        let fadeInAction = SKAction.fadeIn(withDuration: 0.15)
        self.run(fadeInAction)
    }
    
    func hide() {
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.15)
        self.run(fadeOutAction)
    }
    
 
    func showLoading() {
        if !isLoading {
            isLoading = true
            previewNode.isHidden = true
            loadingIndicator.isHidden = false
            
            // Animación de rotación para el indicador de carga
            let rotateAction = SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi * 2), duration: 1.0))
            loadingIndicator.run(rotateAction, withKey: "loading")
        }
    }
    
    func hideLoading() {
        if isLoading {
            isLoading = false
            previewNode.isHidden = false
            loadingIndicator.isHidden = true
            loadingIndicator.removeAction(forKey: "loading")
        }
    }
    
    func updatePreview(with texture: SKTexture) {
        // Actualizar el nodo con la textura y el tamaño calculado
        previewNode.texture = texture
        //previewNode.size = CGSize(width: newWidth, height: newHeight)
        
        // Alinear en el centro pero dejando espacio en la parte inferior para el timeLabel
        previewNode.position = .zero
        
        // Ocultar el indicador de carga
        hideLoading()
    }
    
    private func calculateAspectFitSize(_ originalSize: CGSize) -> CGSize {
        let maxWidth = width - 16
        let maxHeight = height - 32
        
        let widthRatio = maxWidth / originalSize.width
        let heightRatio = maxHeight / originalSize.height
        
        // Usar el ratio más pequeño para mantener la proporción
        let scale = min(widthRatio, heightRatio)
        
        return CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
    }
}
