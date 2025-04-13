import SpriteKit

class Sprite {
    private var textureNode: SKSpriteNode
    private var tweenManager: TweenManager
    private var zIndexPosition: CGFloat = 1
    private var initialPosition: CGPoint
    
    var node: SKSpriteNode {
        return textureNode
    }
    
    func isActive(at time: Int) -> Bool {
        return tweenManager.isActive(at: time)
    }

    var zPosition: CGFloat {
        get { return zIndexPosition }
        set { zIndexPosition = newValue }
    }

    init(texture: SKTexture, origin : Origin = .centre) {
        textureNode = SKSpriteNode(texture: texture)
        textureNode.size = texture.size()
        textureNode.colorBlendFactor = 1
        textureNode.anchorPoint = origin.anchorPoint
        initialPosition = .zero
        tweenManager = TweenManager()
    }
    
    func setInitialPosition(position: CGPoint) {
       initialPosition = position
       textureNode.position = position
   }
    
    func startLoop(startTime: Int, loopCount: Int) {
        tweenManager.startLoop(startTime: startTime, loopCount: loopCount)
    }
    
    func endLoop(){
        tweenManager.endLoop()
    }

    func addFadeTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        tweenManager.addFadeTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }

    func addScaleTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        tweenManager.addScaleTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }
    
    func addMoveYTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        tweenManager.addMoveYTween(easing: easing, startTime: startTime, endTime: endTime, startValue: (startValue - 240) * -1, endValue: (endValue - 240) * -1)
    }
    
    func addMoveXTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        tweenManager.addMoveXTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue - 320, endValue: endValue - 320)
    }
    
    func addScaleVecTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGPoint, endValue: CGPoint) {
        tweenManager.addScaleVecTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }

    func addMoveTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGPoint, endValue: CGPoint) {
        tweenManager.addMoveTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGPoint(x: startValue.x - 320, y: (startValue.y - 240) * -1), endValue: CGPoint(x: endValue.x - 320, y: (endValue.y - 240) * -1))
    }
    
    func addRotateTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        tweenManager.addRotateTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }
    
    func addColorTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: SKColor, endValue: SKColor) {
        tweenManager.addColorTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
    }
    
    func addBlendModeTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int) {
        tweenManager.addBlendModeTween(startTime: startTime, endTime: endTime)
    }

    func update(currentTime: Int, scale: CGFloat) {
        tweenManager.updateTexture(currentTime: currentTime, textureNode: textureNode, scaleSize: scale, initialPosition: initialPosition)
    }
    
    func clone() -> Sprite {
        // Clonar la textura
        let textureCopy = textureNode.texture!
        
        // Crear un nuevo sprite con la misma textura y origen
        let newSprite = Sprite(texture: textureCopy, origin: Origin(rawValue: textureNode.anchorPoint.x == 0.5 && textureNode.anchorPoint.y == 0.5 ? "centre" : "custom") ?? .centre)
        
        // Copiar las propiedades directamente
        newSprite.zPosition = self.zPosition
        newSprite.setInitialPosition(position: self.initialPosition)
        
        // Clonar el nodo de textura con todas sus propiedades
        newSprite.node.position = self.node.position
        newSprite.node.xScale = self.node.xScale
        newSprite.node.yScale = self.node.yScale
        newSprite.node.zRotation = self.node.zRotation
        newSprite.node.alpha = self.node.alpha
        newSprite.node.color = self.node.color
        newSprite.node.colorBlendFactor = self.node.colorBlendFactor
        newSprite.node.blendMode = self.node.blendMode
         newSprite.tweenManager = self.tweenManager
        
        return newSprite
    }
}
