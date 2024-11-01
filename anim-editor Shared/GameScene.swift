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
        
        return scene
    }
    
    let path = "/Users/josepuma/Downloads/179323 Sakamoto Maaya - Okaerinasai (tomatomerde Remix)"
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .black

        let audioFilePath = "/Users/josepuma/Downloads/179323 Sakamoto Maaya - Okaerinasai (tomatomerde Remix)/okaeri.mp3"
        setupAudio(filePath: audioFilePath)
 
        spriteParser = SpriteParser(spriteManager: spriteManager, filePath: path + "/Sakamoto Maaya - Okaerinasai (tomatomerde Remix) (Azer).osb")
        spriteParser.parseSprites()
        
        spriteManager.addToScene(scene: self)
        
        let container = Container(alignment: .topLeft,  scene: self, nodeAlignment: .right){
            SKNode.label("Score: 100 y muchas más cosas que no tengo ni idea jeje")
            SKNode.label("Lives: 3")
        }
        
        addChild(container)
        
        let container2 = Container(alignment: .center,  scene: self, nodeAlignment: .center){
            SKNode.label("容器布局改进", fontSize: 96, fontWeight: .bold)
            //SKNode.label("确保内容水平居中排列", fontWeight: .bold)
        }
        
        addChild(container2)
        
        let container3 = Container(alignment: .bottomLeft,  scene: self){
            SKNode.label("Score: 100 y muchas más cosas que no tengo ni idea jeje")
            SKNode.label("Lives: 3")
        }
        
        addChild(container3)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
       super.didChangeSize(oldSize)
        updateContainerLayouts()
        spriteManager.updateSize()
   }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if audioPlayer != nil{
            let gameTime = Int(audioPlayer.currentTime * 1000) // Convert to milliseconds or your desired unit
            spriteManager.updateAll(currentTime: gameTime)
        }
    }
    
    func setupAudio(filePath: String) {
        let url = URL(fileURLWithPath: filePath)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            totalDuration = audioPlayer.duration
            //audioPlayer.volume = 0
            audioPlayer.play()
            audioPlayer.currentTime = 20
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

