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
    var effects: [Effect] = []
    var analyzer : AudioFFTAnalyzer?
    var effectsTableNode: EffectsTableNode!
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        return scene
    }
    
    let path = "/Users/josepuma/Downloads/387136 BUTAOTOME - Waizatsu Ideology/"
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .black

        let audioFilePath = "/Users/josepuma/Downloads/387136 BUTAOTOME - Waizatsu Ideology/lub.mp3"
        setupAudio(filePath: audioFilePath)
 
        //spriteParser = SpriteParser(spriteManager: spriteManager, filePath: path + "BUTAOTOME - Waizatsu Ideology (Jounzan).osb")
        //spriteParser.parseSprites()
        spriteManager.addToScene(scene: self)
        
        effectsTableNode = EffectsTableNode()
        effectsTableNode.position = CGPoint(x: 0, y: 0)
        effectsTableNode.isUserInteractionEnabled = true
        effectsTableNode.zPosition = 20
        effectsTableNode.parentScene = self
        effectsTableNode.spriteManager = spriteManager
        addChild(effectsTableNode)
        
        let rainTexture = Texture.textureFromLocalPath("/Users/josepuma/Downloads/387136 BUTAOTOME - Waizatsu Ideology/sb/d.png")
        let rainEffect = RainEffect(name: "Rain", parameters: [
            "texture": rainTexture!,
            "numberOfSprites": 2,
            "startTime": 0,
            "endTime": 100000
        ])
        addEffect(rainEffect)

    }
    
    func addEffect(_ effect: Effect) {
        effects.append(effect)
        effect.apply(to: spriteManager, in: self)
        effectsTableNode.effects = effects
        effectsTableNode.reloadData()
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
            //audioPlayer.currentTime = 30
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

