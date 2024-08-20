//
//  GameScene.swift
//  anim-editor Shared
//
//  Created by José Puma on 08-08-24.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    var audioPlayer: AVAudioPlayer!
    var totalDuration: TimeInterval!
    let spriteManager = SpriteManager()
    private var spriteParser: SpriteParser!
    var barsFFT : [SKNode] = []
    var analyzer : AudioFFTAnalyzer?
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        
        return scene
    }
    let path = "/Users/josepuma/Downloads/Baracuda - I Will Love Again (Nightcore Mix) (osuplayer111)/"
    override func didMove(to view: SKView) {
        backgroundColor = .black
        //let fm = FileManager.default
        

        //print()
        let audioFilePath = "/Users/josepuma/Documents/Swtoard/Mr Dj - Baby Alice/audio.mp3"
        setupAudio(filePath: audioFilePath)
 
        //spriteParser = SpriteParser(spriteManager: spriteManager, filePath: path + "Quinn Karter - Living in a Dream (feat. Natalie Major) (Feint Remix) (Asphyxia).osb")
        //spriteParser.parseSprites()
        
        let totalBars = 65
        analyzer = AudioFFTAnalyzer(audioURL: URL(fileURLWithPath: audioFilePath))!
        var startX = -320
        for _ in 0...totalBars{
            let bar = SKSpriteNode(color: .green, size: CGSize(width: 2, height: 5))
            bar.position = CGPoint(x: startX, y: 0)
            bar.anchorPoint = CGPoint(x: 0.5, y: 0)
            barsFFT.append(bar)
            addChild(bar)
            startX += 10
        }
            //var times : [AudioFFT] = []
            /*for audioPosition in stride(from: 1178, to: 60000, by: 50) {
                if let audioFFT = analyzer.getFFTBars(atTime: audioPosition, barCount: totalBars) {
                    times.append(audioFFT)
                    //print(times)
                }
            }
            
            addFFTBars(total: totalBars, times: times)*/
             
        
        
        spriteManager.addToScene(scene: self)
    
    }
    
    func addFFTBars(total: Int, times: [AudioFFT]){
        var startX : CGFloat = 0.0
        for barIndex in 0...total - 1{
            let sprite = Sprite(texture: Texture.textureFromLocalPath(path + "sb/pixel.png")!, origin: .centre)
            sprite.addMoveTween(startTime: 0, endTime: 0, startValue: CGPoint(x: startX, y: 240), endValue: CGPoint(x: startX, y: 240))
            
            
            for timeIndex in times.indices{
                if timeIndex < times.count - 1{
                    let startScaleY = (CGFloat(times[timeIndex].bars[barIndex]) * 60) + 2
                    let endScaleY = (CGFloat(times[timeIndex + 1].bars[barIndex]) * 60) + 2
                    sprite.addScaleVecTween(easing: .linear, startTime: times[timeIndex].startTime, endTime: times[timeIndex + 1].startTime, startValue: CGPoint(x: 5, y: startScaleY), endValue: CGPoint(x: 5, y: endScaleY))
                }
            }
            
            spriteManager.addSprite(sprite)
            startX += 10
        }
        /*for bar in bars{
            let sprite = Sprite(texture: Texture.textureFromLocalPath(path + "sb/8.png")!, origin: .centre)
            sprite.addMoveTween(startTime: 0, endTime: 10000, startValue: CGPoint(x: startX, y: 370), endValue: CGPoint(x: startX, y: 370))
            sprite.addScaleVecTween(startTime: 0, endTime: 10000, startValue: CGPoint(x: 1, y: CGFloat(bar)), endValue: CGPoint(x: 1, y: CGFloat(bar)))
            spriteManager.addSprite(sprite)
            startX += 10
        }*/
    }

    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if audioPlayer != nil{
            let gameTime = Int(audioPlayer.currentTime * 1000) // Convert to milliseconds or your desired unit
            spriteManager.updateAll(currentTime: gameTime)
            if let audioFFT = analyzer?.getFFTBars(atTime: gameTime, barCount: barsFFT.count) {
                var index = 0
                for bar in barsFFT{
                    let value = audioFFT.bars[index]
                    bar.yScale = CGFloat(value * 20) + 0.1
                    index += 1
                }
            }
            
            
        }
    }
    
    func setupAudio(filePath: String) {
        let url = URL(fileURLWithPath: filePath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            totalDuration = audioPlayer.duration
            audioPlayer.play()
            //audioPlayer.volume = 0.1
            //audioPlayer.play()
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        self.atPoint(event.location(in: self)).mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {

    }
    
    override func mouseUp(with event: NSEvent) {

    }

}
#endif

