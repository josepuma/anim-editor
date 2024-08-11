//
//  GameViewController.swift
//  anim-editor macOS
//
//  Created by José Puma on 08-08-24.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.newGameScene()
        
        // Present the scene
        let skView = self.view as! SKView
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = false
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

}

