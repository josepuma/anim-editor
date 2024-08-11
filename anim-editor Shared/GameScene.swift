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
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        
        return scene
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        //let fm = FileManager.default
        let path = "/Users/josepuma/Downloads/292814 SARINA PARIS - LOOK AT US (Daddy DJ Remix)/"

        //print()
        let audioFilePath = path + "track.mp3"
        setupAudio(filePath: audioFilePath)
 
        spriteParser = SpriteParser(spriteManager: spriteManager, filePath: path + "SARINA PARIS - LOOK AT US (Daddy DJ Remix) (Kazuya).osb")
        spriteParser.parseSprites()
        spriteManager.addToScene(scene: self)
        
        let textInputNode = TextInput(size: CGSize(width: 200, height: 20))
        textInputNode.position = CGPoint(x: 0, y: 0)
        addChild(textInputNode)
        
        // Call setupTextField after the node is added to the scene
        textInputNode.setupTextField(in: view)
    
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
            audioPlayer.volume = 0.1
            audioPlayer.play()
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

