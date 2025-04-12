//
//  EffectsTableNode.swift
//  anim-editor
//
//  Created by José Puma on 31-12-24.
//

import SpriteKit

class EffectsTableNode: SKNode {
    var effects: [Effect] = []
    var spriteManager: SpriteManager!
    var parentScene: SKScene!
    
    override init() {
        super.init()
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadData() {
        removeAllChildren()
        
        for (effectIndex, effect) in effects.enumerated() {
            // Effect name
            let effectLabelNode = SKLabelNode(text: effect.name)
            effectLabelNode.fontName = "Helvetica"
            effectLabelNode.fontSize = 14
            effectLabelNode.position = CGPoint(x: 0, y: -CGFloat(effectIndex) * 60)
            addChild(effectLabelNode)
            
            var parameterIndex = 0
            for (parameter, value) in effect.parameters {
                // Parameter label
                let parameterLabelNode = SKLabelNode(text: "\(parameter):")
                parameterLabelNode.fontName = "Helvetica"
                parameterLabelNode.fontSize = 12
                parameterLabelNode.position = CGPoint(x: 0, y: -CGFloat(effectIndex) * 60 - CGFloat(parameterIndex + 1) * 20)
                addChild(parameterLabelNode)

                // Parameter input field
                let inputNode = InputFieldNode(text: "\(value)")
                inputNode.position = CGPoint(x: 150, y: parameterLabelNode.position.y)
                inputNode.name = "input_\(effectIndex)_\(parameter)"
                addChild(inputNode)

                parameterIndex += 1
            }
        }
    }
    
    func updateEffectParameter(at index: Int, parameter: String, value: Any) {
        let effect = effects[index]
        effect.parameters[parameter] = value
        effect.removeSprites(from: spriteManager)
        effect.apply(to: spriteManager, in: parentScene)
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodes = nodes(at: location)
        
        for node in nodes {
            if let inputNode = node as? InputFieldNode {
                inputNode.startEditing(in: self.scene!.view!)
                break
            }
        }
    }
}
