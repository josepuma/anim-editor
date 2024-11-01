import SpriteKit

class Sprite {
    private var textureNode: SKSpriteNode
    private var tweenManager: TweenManager
    private var zIndexPosition: CGFloat = 1

    init(texture: SKTexture, origin : Origin = .centre) {
        textureNode = SKSpriteNode(texture: texture)
        textureNode.size = texture.size()
        textureNode.colorBlendFactor = 1
        textureNode.anchorPoint = origin.anchorPoint
        tweenManager = TweenManager()
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
        tweenManager.updateTexture(currentTime: currentTime, textureNode: textureNode, scaleSize: scale)
    }
    
    func clone() -> Sprite {
        let textureCopy = textureNode.texture!.copy() as! SKTexture
        let newSprite = Sprite(texture: textureCopy)
        newSprite.textureNode = textureNode.copyNode()
        newSprite.tweenManager = tweenManager // Asumiendo que TweenManager se puede compartir
        newSprite.zPosition = zIndexPosition
        return newSprite
    }

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
}

extension SKSpriteNode {
    func copyNode() -> SKSpriteNode {
        let copy = SKSpriteNode(texture: self.texture)
        copy.position = self.position
        copy.zPosition = self.zPosition
        copy.xScale = self.xScale
        copy.yScale = self.yScale
        copy.zRotation = self.zRotation
        copy.alpha = self.alpha
        copy.isHidden = self.isHidden
        return copy
    }
}
