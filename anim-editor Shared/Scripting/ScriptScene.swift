//
//  ScriptScene.swift
//  anim-editor
//
//  Created by José Puma on 27-04-25.
//

import SpriteKit

class ScriptScene: SKNode {
    var scriptName: String
    private var sprites: [Sprite] = []
    private var scale: CGFloat = 1.0
    
    init(scriptName: String) {
        self.scriptName = scriptName
        super.init()
        
        self.name = "script_\(scriptName)"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSprite(_ sprite: Sprite) {
        sprites.append(sprite)
        addChild(sprite.node)
    }
    
    func clearAllSprites() {
        // Remover cada sprite de forma explícita
        for sprite in sprites {
            sprite.node.removeFromParent()
        }
        
        // Limpiar el array
        sprites.removeAll()
        
        // Depuración
        print("🧹 Escena \(scriptName): Se eliminaron \(sprites.count) sprites")
    }
    
    func update(atTime time: Int) {
        for sprite in sprites {
            sprite.update(currentTime: time, scale: scale)
        }
    }
    
    func setContentScale(_ newScale: CGFloat) {
        self.scale = newScale
    }
    
    func getSprites() -> [Sprite] {
        return sprites
    }
    
    func fadeOut(duration: TimeInterval = 0.2, completion: (() -> Void)? = nil) {
        let fadeOutAction = SKAction.fadeOut(withDuration: duration)
        
        if let completion = completion {
            // Añadir una acción de función para llamar al completion
            let completeAction = SKAction.run(completion)
            let sequence = SKAction.sequence([fadeOutAction, completeAction])
            self.run(sequence)
        } else {
            self.run(fadeOutAction)
        }
    }

    /// Aplica un efecto de fade in
    /// - Parameter duration: Duración de la animación en segundos
    func fadeIn(duration: TimeInterval = 0.3) {
        // Asegurarse de que la escena comienza invisible
        self.alpha = 0
        
        // Aplicar fade in
        let fadeInAction = SKAction.fadeIn(withDuration: duration)
        self.run(fadeInAction)
    }
}
