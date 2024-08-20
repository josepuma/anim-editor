import SpriteKit

class SpriteManager {
     var sprites: [Sprite] = []
    private var currentZPosition: CGFloat = 1

    func addSprite(_ sprite: Sprite) {
        sprite.zPosition = currentZPosition
        sprites.append(sprite)
        currentZPosition += 1
    }
    
    func addSprites(_ spritesList: [Sprite]){
        sprites.append(contentsOf: spritesList)
    }

    func addToScene(scene: SKScene) {
        for sprite in sprites {
            scene.addChild(sprite.node)
        }
    }
    
    func updateAll(currentTime: Int) {
        for sprite in sprites {
            sprite.update(currentTime: currentTime)
        }
    }
    
    func textureForTime(time: Int, size: CGSize, completion: @escaping (SKTexture) -> Void) {
        DispatchQueue.main.async {
            let popupScene = SKScene(size: size)
            popupScene.backgroundColor = .black
            popupScene.scaleMode = .aspectFit

            let activeSpritesAtPosition = self.sprites.filter { $0.isActive(at: time) }
            for sprite in activeSpritesAtPosition {
                let spriteCopy = sprite.clone()
                spriteCopy.update(currentTime: time)
                spriteCopy.node.xScale = (spriteCopy.node.xScale) * 0.2
                spriteCopy.node.yScale = (spriteCopy.node.yScale) * 0.2
                spriteCopy.node.position.x = (spriteCopy.node.position.x + 427) * 0.2
                spriteCopy.node.position.y = (spriteCopy.node.position.y + 240) * 0.2
                popupScene.addChild(spriteCopy.node)
            }

            let view = SKView()
            let texture = view.texture(from: popupScene)!
            
            // Call completion on the main thread (we're already on the main thread)
            completion(texture)
        }
    }




}
