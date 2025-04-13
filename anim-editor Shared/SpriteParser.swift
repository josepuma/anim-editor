import SpriteKit

class SpriteParser {
    private var spriteManager: SpriteManager
    private var filePath: String
    private var textureCache: [String: SKTexture] = [:]
    
    init(spriteManager: SpriteManager, filePath: String) {
        self.spriteManager = spriteManager
        self.filePath = filePath
    }
    
    func getTexture(from texturePath: String) -> SKTexture? {
        let path = "/Users/josepuma/Downloads/1151309 Stonebank - Be Alright (feat. EMEL) (Cut Ver.)"
           // Check if the texture is already in the cache
           if let cachedTexture = textureCache[texturePath] {
               return cachedTexture
           }

           // If not, create a new texture and add it to the cache
        if let texture = Texture.textureFromLocalPath("\(path)/\(texturePath)") {
               textureCache[texturePath] = texture
               return texture
           }

           // If the texture could not be created, return nil
           return nil
       }
    
    func parseSprites() {
        do{
            let fileURL = URL(fileURLWithPath: filePath)
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n")
            var currentSprite: Sprite?
            var texturePath: String?
            var position: CGPoint = CGPoint(x: 0, y: 0)
            var isLoopCommandCreated = false
            for line in lines {
                let isLoopCommand = line.starts(with: "  ")
                
                if isLoopCommandCreated && !isLoopCommand{
                    currentSprite?.endLoop()
                    isLoopCommandCreated = false
                }
                
                let parts = line.trimmingCharacters(in: .whitespaces).split(separator: ",", omittingEmptySubsequences: false)
                if parts.isEmpty {
                    continue
                }
                
                switch parts[0] {
                case "Sprite":
                    if let currentSprite = currentSprite {
                        spriteManager.addSprite(currentSprite)
                    }
                    
                    // Extract sprite properties
                    guard parts.count >= 5 else {
                        print("Invalid Sprite line format.")
                        continue
                    }
                    
                    texturePath = String(parts[3]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\\", with: "/").replacingOccurrences(of: "\"", with: "")
                    if let x = Double(parts[4]), let y = Double(parts[5]) {
                        position = CGPoint(x: x - 320, y: (y - 240) * -1)
                    }
                
                    
                    // Create the new sprite with the texture path and position
                    if let texturePath = texturePath, let texture = getTexture(from: "\(texturePath)") {
                        let originName = String(parts[2]).camelCased
                        currentSprite = Sprite(texture: texture, origin: Origin(rawValue: originName) ?? .centre)
                        currentSprite?.setInitialPosition(position: position)
                        //currentSprite?.node.position = position
                    }
                    break;
                    
                case "F":
                    // Fade tween
                    guard let currentSprite = currentSprite else {
                        print("Invalid Fade line format.")
                        continue
                    }
                    if let startTime = Int(parts[2]), let startValue = Double(parts[4]) {
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        let endTime = Int(parts[3]) ?? startTime
                        let endValue = parts.count > 5 ? Double(parts[5]) : startValue
                        currentSprite.addFadeTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGFloat(startValue), endValue: endValue ?? CGFloat(startValue))
                    }
                    break;
                    
                case "S":
                    guard let currentSprite = currentSprite else {
                        print("Invalid Scale line format.")
                        continue
                    }
                    if let startTime = Int(parts[2]), let startValue = Double(parts[4]) {
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        let endTime = Int(parts[3]) ?? startTime
                        let endValue = parts.count > 5 ? Double(parts[5]) : startValue
                        currentSprite.addScaleTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGFloat(startValue), endValue: endValue ?? CGFloat(startValue))
                    }
                break;
                case "M":
                    // Position tween
                    guard let currentSprite = currentSprite else {
                        print("Invalid Move line format.")
                        continue
                    }
                    
                    if let startTime = Int(parts[2]), let startValueX = Double(parts[4]), let startValueY = Double(parts[5]) {
                        let easingValue = Int(parts[1]) ?? 0
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        
                        let endTime = Int(parts[3]) ?? startTime
                        let endValueX = (parts.count > 7 ? Double(parts[6]) : startValueX) ?? startValueX
                        let endValueY = (parts.count > 7 ? Double(parts[7]) : startValueY) ?? startValueY
                        currentSprite.addMoveTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGPoint(x: startValueX, y: startValueY), endValue: CGPoint(x: endValueX, y: endValueY) )
                    }
                    break;
                case "MX":
                    // Fade tween
                    guard let currentSprite = currentSprite else {
                        print("Invalid MX line format.")
                        continue
                    }
                    if let startTime = Int(parts[2]), let startValue = Double(parts[4]) {
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        let endTime = Int(parts[3]) ?? startTime
                        let endValue = parts.count > 5 ? Double(parts[5]) : startValue
                        currentSprite.addMoveXTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGFloat(startValue), endValue: endValue ?? CGFloat(startValue))
                    }
                    break;
                case "MY":
                    // Fade tween
                    guard let currentSprite = currentSprite else {
                        print("Invalid MY line format.")
                        continue
                    }
                    if let startTime = Int(parts[2]), let startValue = Double(parts[4]) {
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        let endTime = Int(parts[3]) ?? startTime
                        let endValue = parts.count > 5 ? Double(parts[5]) : startValue
                        currentSprite.addMoveYTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGFloat(startValue), endValue: endValue ?? CGFloat(startValue))
                    }
                    break;
                case "V":
                    // Position tween
                    guard let currentSprite = currentSprite else {
                        print("Invalid Move line format.")
                        continue
                    }
                    
                    if let startTime = Int(parts[2]), let startValueX = Double(parts[4]), let startValueY = Double(parts[5]) {
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        let endTime = Int(parts[3]) ?? startTime
                        let endValueX = (parts.count > 7 ? Double(parts[6]) : startValueX) ?? startValueX
                        let endValueY = (parts.count > 7 ? Double(parts[7]) : startValueY) ?? startValueY
                        currentSprite.addScaleVecTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGPoint(x: startValueX, y: startValueY), endValue: CGPoint(x: endValueX, y: endValueY) )
                    }
                    break;
                case "R":
                    guard let currentSprite = currentSprite else {
                        print("Invalid Rotate line format.")
                        continue
                    }
                    if let startTime = Int(parts[2]), let startValue = Double(parts[4]) {
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        let endTime = Int(parts[3]) ?? startTime
                        let endValue = parts.count > 5 ? Double(parts[5]) : startValue
                        currentSprite.addRotateTween(easing: easing, startTime: startTime, endTime: endTime, startValue: CGFloat(startValue), endValue: endValue ?? CGFloat(startValue))
                    }
                    break;
                case "L":
                    if let startTime = Int(parts[1]), let loopCount = Int(parts[2]) {
                        currentSprite?.startLoop(startTime: startTime, loopCount: loopCount)
                        isLoopCommandCreated = true
                    }
                    break;
                case "P":
                    if parts.count > 3{
                        let type = parts[4]
                        switch(type){
                        case "A":
                            guard let currentSprite = currentSprite else {
                                print("Invalid line format.")
                                continue
                            }
                            
                            if let startTime = Int(parts[2]) {
                                let endTime = Int(parts[3]) ?? startTime
                                currentSprite.addBlendModeTween(startTime: startTime, endTime: endTime)
                            }
                            
                        default:
                            print("Unknown command: \(parts[0])")
                        }
                        
                    }
                    break;
                    
                    
                    case "C":
                    // Position tween
                    guard let currentSprite = currentSprite else {
                        print("Invalid Move line format.")
                        continue
                    }
                    
                    if let startTime = Int(parts[2]), let startValueX = Double(parts[4]), let startValueY = Double(parts[5]), let startValueZ = Double(parts[6]){
                        let easing = Easing.allCases[Int(parts[1]) ?? 0]
                        let endTime = Int(parts[3]) ?? startTime
                        let endValueX = (parts.count > 9 ? Double(parts[7]) : startValueX) ?? startValueX
                        let endValueY = (parts.count > 9 ? Double(parts[8]) : startValueY) ?? startValueY
                        let endValueZ = (parts.count > 9 ? Double(parts[9]) : startValueZ) ?? startValueZ
                        currentSprite.addColorTween(easing: easing, startTime: startTime, endTime: endTime, startValue: SKColor(red: startValueX / 255, green: startValueY / 255, blue: startValueZ / 255, alpha: 1), endValue: SKColor(red: endValueX / 255, green: endValueY / 255, blue: endValueZ / 255, alpha: 1) )
                    }
                    break;
                    
                default:
                    print("Unknown command: \(parts[0])")
                }
            }
            
            // Add the last sprite
            if let currentSprite = currentSprite {
                spriteManager.addSprite(currentSprite)
            }
        } catch {
            print("Error reading file: \(error)")
        }
    }
    
   
}

extension String {
    var lowercasingFirst: String { prefix(1).lowercased() + dropFirst() }
    var uppercasingFirst: String { prefix(1).uppercased() + dropFirst() }

    var camelCased: String {
        guard !isEmpty else { return "" }
        let parts = components(separatedBy: .alphanumerics.inverted)
        let first = parts.first!.lowercasingFirst
        let rest = parts.dropFirst().map { $0.uppercasingFirst }

        return ([first] + rest).joined()
    }
}
