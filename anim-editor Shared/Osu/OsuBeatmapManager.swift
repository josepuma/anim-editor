//
//  OsuBeatmapManager.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

import SpriteKit

class OsuBeatmapManager {
    private var spriteManager: SpriteManager
    private var parser: OsuParser?
    private var hitObjects: [OsuHitObject] = []
    internal var textureLoader: TextureLoader
    
    // Texturas
    private var hitcircleTexture: SKTexture
    private var hitcircleOverlayTexture: SKTexture
    private var approachCircleTexture: SKTexture
    private var numberTextures: [SKTexture] = []
    
    init(spriteManager: SpriteManager, texturesPath: String) {
            self.spriteManager = spriteManager
            self.textureLoader = TextureLoader(basePath: texturesPath)
            
            // Inicializar con texturas vacías
            self.hitcircleTexture = SKTexture()
            self.hitcircleOverlayTexture = SKTexture()
            self.approachCircleTexture = SKTexture()
            
            // Cargar las texturas desde los archivos
            if let hitcircle = textureLoader.getTexture(named: "skin/hitcircle.png") {
                self.hitcircleTexture = hitcircle
            } else {
                self.hitcircleTexture = createCircleTexture()
            }
            
            if let overlay = textureLoader.getTexture(named: "skin/hitcircleoverlay.png") {
                self.hitcircleOverlayTexture = overlay
            } else {
                self.hitcircleOverlayTexture = createCircleTexture()
            }
            
            if let approach = textureLoader.getTexture(named: "skin/approachcircle.png") {
                self.approachCircleTexture = approach
            } else {
                self.approachCircleTexture = createApproachCircleTexture()
            }
            
            // Cargar las texturas de números (del 1 al 9)
            for i in 0...9 {
                if let numTexture = textureLoader.getTexture(named: "skin/default-\(i).png") {
                    numberTextures.append(numTexture)
                }
            }
        }
    
    /*init(spriteManager: SpriteManager, texturesPath: String, circleTexture: SKTexture, approachTexture: SKTexture) {
        self.spriteManager = spriteManager
        self.circleTexture = circleTexture
        self.approachTexture = approachTexture
        self.textureLoader = TextureLoader(basePath: texturesPath)
    }*/
    
    private func createCircleTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        let renderer = SKView(frame: CGRect(origin: .zero, size: size))
        
        let scene = SKScene(size: size)
        scene.backgroundColor = .clear
        
        let circle = SKShapeNode(circleOfRadius: 30)
        circle.fillColor = .white
        circle.strokeColor = .red
        circle.lineWidth = 2
        circle.position = CGPoint(x: size.width/2, y: size.height/2)
        scene.addChild(circle)
        
        return renderer.texture(from: scene) ?? SKTexture()
    }
    
    private func createApproachCircleTexture() -> SKTexture {
        let size = CGSize(width: 64, height: 64)
        let renderer = SKView(frame: CGRect(origin: .zero, size: size))
        
        let scene = SKScene(size: size)
        scene.backgroundColor = .clear
        
        let circle = SKShapeNode(circleOfRadius: 30)
        circle.fillColor = .clear
        circle.strokeColor = .blue
        circle.lineWidth = 2
        circle.position = CGPoint(x: size.width/2, y: size.height/2)
        scene.addChild(circle)
        
        return renderer.texture(from: scene) ?? SKTexture()
    }
    
    func loadBeatmap(filePath: String) -> Bool {
        // Crear parser
        parser = OsuParser(
            filePath: filePath,
            spriteManager: spriteManager,
            hitcircleTexture: hitcircleTexture,
            hitcircleOverlayTexture: hitcircleOverlayTexture,
            approachCircleTexture: approachCircleTexture,
            numberTextures: numberTextures
        )
        
        // Parsear el beatmap
        parser?.parse()
        
        // Obtener objetos parseados
        if let hitObjects = parser?.getHitObjects(), !hitObjects.isEmpty {
            self.hitObjects = hitObjects
            return true
        }
        
        return false
    }
    
    func renderBeatmap() {
        // Crear sprites para todos los objetos
        parser?.createSprites()
    }
    
    func getBeatmapInfo() -> [String: String]? {
        return parser?.getBeatmapInfo()
    }
    
    func getHitObjects() -> [OsuHitObject] {
        return hitObjects
    }
}
