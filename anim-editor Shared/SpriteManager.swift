import SpriteKit

class SpriteManager {
    var sprites: [Sprite] = []
    private weak var parentScene: SKScene?
    private var currentZPosition: CGFloat = 1
    private var scale: CGFloat = 1

    func addSprite(_ sprite: Sprite) {
        sprite.zPosition = currentZPosition
        sprites.append(sprite)
        currentZPosition += 1
        if let scene = parentScene {
            scene.addChild(sprite.node)
        }
    }
    
    func addSprites(_ spritesList: [Sprite]){
        sprites.append(contentsOf: spritesList)
    }

    func addToScene(scene: SKScene) {
        self.parentScene = scene
        for sprite in sprites {
            scene.addChild(sprite.node)
        }
    }
    
    func updateSize(){
        guard let scene = parentScene else { return }
        let sceneSize = scene.size
        scale = 854 / sceneSize.width
    }
    
    func updateAll(currentTime: Int) {
        for sprite in sprites {
            sprite.update(currentTime: currentTime, scale: scale)
        }
    }
    
    func removeSprite(_ sprite: Sprite) {
        if let index = sprites.firstIndex(where: { $0 === sprite }) {
            sprites.remove(at: index)
            sprite.node.removeFromParent()
        }
    }
    
    func textureForTime(time: Int, size: CGSize, completion: @escaping (SKTexture) -> Void) {
        DispatchQueue.main.async {
            // Crear una escena para la vista previa con el tamaño solicitado
            let popupScene = SKScene(size: size)
            popupScene.backgroundColor = .black
            popupScene.scaleMode = .aspectFit
            popupScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            
            // Filtrar sprites activos en ese momento
            let activeSpritesAtPosition = self.sprites.filter { $0.isActive(at: time) }
            
            if activeSpritesAtPosition.isEmpty {
                // Si no hay sprites activos, mostrar un mensaje
                let noContentLabel = SKLabelNode(text: "No content at this time")
                noContentLabel.fontColor = .white
                noContentLabel.fontSize = 14
                noContentLabel.position = CGPoint(x: size.width/2, y: size.height/2)
                popupScene.addChild(noContentLabel)
            } else {
                let scale = CGFloat(854 / 256)
                
                // Añadir los sprites a la escena temporal
                for sprite in activeSpritesAtPosition {
                    // Crear una copia para no afectar los sprites originales
                    let spriteCopy = sprite.clone()
                    
                    // Actualizar al tiempo correcto
                    spriteCopy.update(currentTime: time, scale: scale)
                    
                    popupScene.addChild(spriteCopy.node)
                }
            }
            
            // Generar la textura
            let view = SKView()
            if let texture = view.texture(from: popupScene) {
                completion(texture)
            } else {
                // Textura de respaldo en caso de error
                let fallbackScene = SKScene(size: size)
                fallbackScene.backgroundColor = .darkGray
                
                let errorLabel = SKLabelNode(text: "Preview unavailable")
                errorLabel.fontColor = .white
                errorLabel.fontSize = 14
                errorLabel.position = CGPoint(x: size.width/2, y: size.height/2)
                fallbackScene.addChild(errorLabel)
                
                let fallbackTexture = view.texture(from: fallbackScene)!
                completion(fallbackTexture)
            }
        }
    }

}

extension SpriteManager {
    func getSpriteForNode(_ node: SKNode) -> Sprite? {
        for sprite in sprites {
            if node == sprite.node || node.parent == sprite.node {
                return sprite
            }
        }
        return nil
    }
}
