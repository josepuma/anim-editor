import SpriteKit

class TweenManager {
    
    struct Loop {
       let startTime: Int
       let loopCount: Int
       var tweens: [Any]
       var duration: Int
       var earliestInnerStart: Int
       var latestInnerEnd: Int
       var fadeTweensLoop: [Tween<CGFloat>] = []
       var scaleTweensLoop: [Tween<CGFloat>] = []
       var moveXTweens: [Tween<CGFloat>] = []
       var moveYTweens: [Tween<CGFloat>] = []
       var moveTweens: [Tween<CGPoint>] = []
       var scaleVecTweens: [Tween<CGPoint>] = []
       var colorTweens: [Tween<SKColor>] = []
       var rotateTweens: [Tween<CGFloat>] = []
   }
    
    struct Keyframe<T> {
        let time: Int
        let value: T
    }

    struct Tween<T> {
        var easing: Easing
        var startTime: Int
        var endTime: Int
        var startValue: T
        var endValue: T
    }
    
    
    private var loops: [Loop] = []
    private var fadeTweens: [Tween<CGFloat>] = []
    private var scaleTweens: [Tween<CGFloat>] = []
    private var moveXTweens: [Tween<CGFloat>] = []
    private var moveYTweens: [Tween<CGFloat>] = []
    private var moveTweens: [Tween<CGPoint>] = []
    private var scaleVecTweens: [Tween<CGPoint>] = []
    private var rotateTweens: [Tween<CGFloat>] = []
    private var colorTweens: [Tween<SKColor>] = []
    private var blendModeKeyframes: [Keyframe<CGFloat>] = []
    private var blendModeTweens: [Tween<CGFloat>] = []
    
    private var startTimes: [Int] = []
    private var endTimes: [Int] = []
    
    private var earlyStartTime: Int?
    private var latestEndTime: Int?
    
    private var currentLoop: Loop?
        
    func startLoop(startTime: Int, loopCount: Int) {
        currentLoop = Loop(startTime: startTime, loopCount: loopCount, tweens: [], duration: 0, earliestInnerStart: Int.max, latestInnerEnd: 0)
    }
    
    func endLoop() {
        if let loop = currentLoop {
            let loopTotalDuration = loop.duration * loop.loopCount
            let loopEndTime = loop.startTime + loopTotalDuration
            
            startTimes.append(loop.startTime)
            endTimes.append(loopEndTime)
            
            fadeTweens.append(contentsOf: generateTweens(loop: loop, tweens: loop.fadeTweensLoop))
            scaleTweens.append(contentsOf: generateTweens(loop: loop, tweens: loop.scaleTweensLoop))
            moveXTweens.append(contentsOf: generateTweens(loop: loop, tweens: loop.moveXTweens))
            moveYTweens.append(contentsOf: generateTweens(loop: loop, tweens: loop.moveYTweens))
            rotateTweens.append(contentsOf: generateTweens(loop: loop, tweens: loop.rotateTweens))
            
            scaleVecTweens.append(contentsOf: generate2DTweens(loop: loop, tweens: loop.scaleVecTweens))
            moveTweens.append(contentsOf: generate2DTweens(loop: loop, tweens: loop.moveTweens))
            
            colorTweens.append(contentsOf: generateColorTweens(loop: loop, tweens: loop.colorTweens))

            loops.append(loop)
            currentLoop = nil
        }
    }
    
    func generateTweens(loop: Loop, tweens: [Tween<CGFloat>]) -> [Tween<CGFloat>]{
        var newTweens : [Tween<CGFloat>] = []
        var loopStartTime = loop.startTime
        for _ in 1...loop.loopCount{
            for tween in tweens{
                let offset = tween.endTime - tween.startTime
                let loopEndTime = loopStartTime + offset
                let newTween = Tween(easing: tween.easing, startTime: loopStartTime, endTime: loopEndTime, startValue: tween.startValue, endValue: tween.endValue)
                newTweens.append(newTween)
                loopStartTime += offset
            }
        }
        return newTweens
    }
    
    func generate2DTweens(loop: Loop, tweens: [Tween<CGPoint>]) -> [Tween<CGPoint>]{
        var newTweens : [Tween<CGPoint>] = []
        var loopStartTime = loop.startTime
        for _ in 1...loop.loopCount{
            for tween in tweens{
                let offset = tween.endTime - tween.startTime
                let loopEndTime = loopStartTime + offset
                let newTween = Tween(easing: tween.easing, startTime: loopStartTime, endTime: loopEndTime, startValue: tween.startValue, endValue: tween.endValue)
                newTweens.append(newTween)
                loopStartTime += offset
            }
        }
        return newTweens
    }
    
    func generateColorTweens(loop: Loop, tweens: [Tween<SKColor>]) -> [Tween<SKColor>]{
        var newTweens : [Tween<SKColor>] = []
        var loopStartTime = loop.startTime
        for _ in 1...loop.loopCount{
            for tween in tweens{
                let offset = tween.endTime - tween.startTime
                let loopEndTime = loopStartTime + offset
                let newTween = Tween(easing: tween.easing, startTime: loopStartTime, endTime: loopEndTime, startValue: tween.startValue, endValue: tween.endValue)
                newTweens.append(newTween)
                loopStartTime += offset
            }
        }
        return newTweens
    }

    func addFadeTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.fadeTweensLoop.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            fadeTweens.append(tween)
            fadeTweens.sort { $0.startTime < $1.startTime }
        }
    }
    
    func addMoveXTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.moveXTweens.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            moveXTweens.append(tween)
            moveXTweens.sort { $0.startTime < $1.startTime }
        }
       
    }
    
    func addMoveYTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.moveYTweens.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            moveYTweens.append(tween)
            moveYTweens.sort { $0.startTime < $1.startTime }
        }
    }

    func addScaleTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.scaleTweensLoop.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            scaleTweens.append(tween)
            scaleTweens.sort { $0.startTime < $1.startTime }
        }
        
    }
    
    func addScaleVecTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGPoint, endValue: CGPoint) {
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.scaleVecTweens.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            scaleVecTweens.append(tween)
            scaleVecTweens.sort { $0.startTime < $1.startTime }
        }
    }
    
    func addRotateTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGFloat, endValue: CGFloat) {
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.rotateTweens.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            rotateTweens.append(tween)
            // Sort keyframes and tweens
            rotateTweens.sort { $0.startTime < $1.startTime }
        }
        
    }
    
    func addMoveTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: CGPoint, endValue: CGPoint){
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.moveTweens.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            moveTweens.append(tween)
            // Sort keyframes and tweens
            moveTweens.sort { $0.startTime < $1.startTime }
        }
    }
    
    func addColorTween(easing: Easing = Easing.linear, startTime: Int, endTime: Int, startValue: SKColor, endValue: SKColor) {
        let tween = Tween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
        if var currentLoop = currentLoop {
            currentLoop.colorTweens.append(tween)
            currentLoop.duration = max(currentLoop.duration, endTime)
            currentLoop.earliestInnerStart = min(currentLoop.earliestInnerStart, startTime)
            currentLoop.latestInnerEnd = max(currentLoop.latestInnerEnd, endTime)
            self.currentLoop = currentLoop
        } else {
            startTimes.append(startTime)
            endTimes.append(endTime)
            colorTweens.append(tween)
            colorTweens.sort { $0.startTime < $1.startTime }
        }

    }
    
    func addBlendModeTween(startTime: Int, endTime: Int){
        
        startTimes.append(startTime)
        endTimes.append(endTime)
        
        if startTime == endTime {
            blendModeKeyframes.append(Keyframe(time: startTime, value: 0))
        } else {
            blendModeTweens.append(Tween(easing: .linear, startTime: startTime, endTime: endTime, startValue: 0, endValue: 0))
        }
        
        // Sort keyframes and tweens
        blendModeKeyframes.sort { $0.time < $1.time }
        blendModeTweens.sort { $0.startTime < $1.startTime }
    }
    
    private func updateTiming() {
        earlyStartTime = startTimes.min()
        latestEndTime = endTimes.max()
    }

    func updateTexture(currentTime: Int, textureNode: SKSpriteNode, scaleSize: CGFloat, initialPosition: CGPoint) {
        var blendMode: SKBlendMode = .alpha
        var scale : CGPoint = CGPoint(x: 1, y: 1)
        var alpha = CGFloat(0)
        if earlyStartTime == nil || latestEndTime == nil {
            updateTiming()
        }
        
        guard let earlyStartTime = earlyStartTime, let latestEndTime = latestEndTime, currentTime >= earlyStartTime, currentTime <= latestEndTime else {
            textureNode.isHidden = true
            return
        }
        
        alpha = calculateValue(currentTime: currentTime, tweens: fadeTweens, defaultValue: 1)
        
        if scaleVecTweens.count > 0{
            scale = calculate2DValue(currentTime: currentTime, tweens: scaleVecTweens, defaultValue: CGPoint(x: 1, y: 1))
        }else{
            let newScale = calculateValue(currentTime: currentTime, tweens: scaleTweens, defaultValue: 1)
            scale = CGPoint(x: newScale, y: newScale)
        }
        
        
        textureNode.isHidden = alpha < 0.001 || (scale.x == 0.0 && scale.y == 0)
        
        if textureNode.isHidden {
            return
        }
        
        if moveTweens.count > 0 {
            let pos = calculate2DValue(currentTime: currentTime, tweens: moveTweens, defaultValue: initialPosition)
            textureNode.position.x = pos.x / scaleSize
            textureNode.position.y = pos.y / scaleSize
        } else if moveXTweens.count > 0 || moveYTweens.count > 0 {
            textureNode.position.x = calculateValue(currentTime: currentTime, tweens: moveXTweens, defaultValue: initialPosition.x) / scaleSize
            textureNode.position.y = calculateValue(currentTime: currentTime, tweens: moveYTweens, defaultValue: initialPosition.y) / scaleSize
        } else {
            // Si no hay tweens de movimiento, usar la posición inicial escalada
            textureNode.position.x = initialPosition.x / scaleSize
            textureNode.position.y = initialPosition.y / scaleSize
        }
        

        let latestBlendModeKeyframe = blendModeKeyframes.last { $0.time <= currentTime }
        
        let currentBlendModeTween = blendModeTweens.first { tween in
            currentTime >= tween.startTime && currentTime <= tween.endTime
        }
        
        // Handle blend mode tweening
        if let _ = currentBlendModeTween {
            blendMode = .add
        } else {
            if let _ = latestBlendModeKeyframe {
                // If we have both a keyframe and a tween, use the more recent one
                blendMode =  .add
            }else{
                blendMode = .alpha
            }
        }
        //print(alpha, scale.x, scale.y, textureNode.isHidden)
        textureNode.alpha = alpha
        textureNode.xScale = scale.x / scaleSize
        textureNode.yScale = scale.y / scaleSize
        textureNode.zRotation = calculateValue(currentTime: currentTime, tweens: rotateTweens, defaultValue: 0) * -1
        textureNode.blendMode = blendMode
        textureNode.colorBlendFactor = 1
        textureNode.color = calculateColorValue(currentTime: currentTime, tweens: colorTweens, defaultValue: SKColor.white)
        
    }
    
  
    private func calculateValue(currentTime: Int, tweens: [Tween<CGFloat>], defaultValue: CGFloat) -> CGFloat {
        guard !tweens.isEmpty else {
            return defaultValue
        }

        var low = 0
        var high = tweens.count - 1
        var latestCompletedTween: Tween<CGFloat>? = nil

        while low <= high {
            let mid = (low + high) / 2
            let tween = tweens[mid]

            if tween.startTime <= currentTime && tween.endTime >= currentTime {
                // Current tween found
                let progress = CGFloat(currentTime - tween.startTime) / CGFloat(tween.endTime - tween.startTime)
                let easingProgress = tween.easing.getEasingValue(progress: progress)
                return tween.startValue + (tween.endValue - tween.startValue) * easingProgress
            } else if tween.endTime < currentTime {
                latestCompletedTween = tween
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        // If we're here, we didn't find a current tween
        if let latestTween = latestCompletedTween {
            return latestTween.endValue
        } else if currentTime < tweens[0].startTime {
            return tweens[0].startValue
        } else {
            return defaultValue
        }
    }
    
    private func calculate2DValue(currentTime: Int, tweens: [Tween<CGPoint>], defaultValue: CGPoint) -> CGPoint {
        guard !tweens.isEmpty else {
            return defaultValue
        }

        var low = 0
        var high = tweens.count - 1
        var latestCompletedTween: Tween<CGPoint>? = nil

        while low <= high {
            let mid = (low + high) / 2
            let tween = tweens[mid]

            if tween.startTime <= currentTime && tween.endTime >= currentTime {
                // Current tween found
                let progress = CGFloat(currentTime - tween.startTime) / CGFloat(tween.endTime - tween.startTime)
                let easingProgress = tween.easing.getEasingValue(progress: progress)
            
                return CGPoint(
                    x: tween.startValue.x + (tween.endValue.x - tween.startValue.x) * easingProgress,
                    y: tween.startValue.y + (tween.endValue.y - tween.startValue.y) * easingProgress
                )
            } else if tween.endTime < currentTime {
                latestCompletedTween = tween
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        // If we're here, we didn't find a current tween
        if let latestTween = latestCompletedTween {
            return latestTween.endValue
        } else if currentTime < tweens[0].startTime {
            return tweens[0].startValue
        } else {
            return defaultValue
        }
    }
    
    private func calculateColorValue(currentTime: Int, tweens: [Tween<SKColor>], defaultValue: SKColor) -> SKColor {
        guard !tweens.isEmpty else {
            return defaultValue
        }

        var latestTween: Tween<SKColor>?
        var currentTween: Tween<SKColor>?

        for tween in tweens {
            if tween.startTime <= currentTime && tween.endTime >= currentTime {
                currentTween = tween
                break
            } else if tween.endTime <= currentTime {
                latestTween = tween
            }
        }

        if let tween = currentTween {
            let progress = CGFloat(currentTime - tween.startTime) / CGFloat(tween.endTime - tween.startTime)
            let startComponents = tween.startValue.cgColor.components ?? [0, 0, 0, 0]
            let endComponents = tween.endValue.cgColor.components ?? [0, 0, 0, 0]
            
            let red = startComponents[0] + (endComponents[0] - startComponents[0]) * progress
            let green = startComponents[1] + (endComponents[1] - startComponents[1]) * progress
            let blue = startComponents[2] + (endComponents[2] - startComponents[2]) * progress
            let alpha = startComponents[3] + (endComponents[3] - startComponents[3]) * progress
            
            return SKColor(red: red, green: green, blue: blue, alpha: alpha)
        } else if let tween = latestTween {
            return tween.endValue
        } else {
            return tweens.first?.startValue ?? defaultValue
        }
    }
    
    func isActive(at time: Int) -> Bool {
        
        guard  let earlyStartTime = earlyStartTime, let latestEndTime = latestEndTime else{
            return false
        }
        
        if earlyStartTime <= time && latestEndTime >= time{
            let alpha = calculateValue(currentTime: time, tweens: fadeTweens, defaultValue: 1)
            if alpha < 0.0001{
                return false
            }
            return true
        }
        
        return false
    
    }


}

extension TweenManager {
    // Métodos para acceder a los diferentes tipos de tweens
    func getMoveTweens() -> [Tween<CGPoint>] {
        return moveTweens
    }
    
    func getScaleTweens() -> [Tween<CGFloat>] {
        return scaleTweens
    }
    
    func getRotateTweens() -> [Tween<CGFloat>] {
        return rotateTweens
    }
    
    func getFadeTweens() -> [Tween<CGFloat>] {
        return fadeTweens
    }
    
    func getColorTweens() -> [Tween<SKColor>] {
        return colorTweens
    }
}
