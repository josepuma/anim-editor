//
//  VolumeSlider.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

class VolumeSlider: SKNode {
    // Visual components
    private var trackNode: SKShapeNode
    private var knobNode: SKShapeNode
    
    // Size and layout properties
    private var sliderWidth: CGFloat
    private var trackHeight: CGFloat
    private var knobSize: CGFloat
    private var value: CGFloat = 0.0 // 0.0 to 1.0
    
    private var backgroundColor = NSColor(red: 28 / 255, green: 28 / 255, blue: 42 / 255, alpha: 1)
    private var accent = NSColor(red: 202 / 255, green: 217 / 255, blue: 91 / 255, alpha: 1)
    // Interaction tracking
    private var isDragging = false
    
    // Callback for value changes
    var onVolumeChange: ((CGFloat) -> Void)?
    
    init(width: CGFloat = 100, height: CGFloat = 4, knobSize: CGFloat = 12) {
        self.sliderWidth = width
        self.trackHeight = height
        self.knobSize = knobSize
        
        // Create track (the slider background line)
        trackNode = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height/2)
        trackNode.fillColor = backgroundColor
        trackNode.strokeColor = backgroundColor
        trackNode.lineWidth = 0.5
        
        // Create knob (the draggable part)
        knobNode = SKShapeNode(circleOfRadius: knobSize/2)
        knobNode.fillColor = accent
        knobNode.strokeColor = accent
        knobNode.lineWidth = 1.0
        
        
        super.init()
        
        // Add nodes to self
        addChild(trackNode)
        addChild(knobNode)
        // Set initial knob position (default to 0)
        updateKnobPosition()
        
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateKnobPosition() {
        // Calculate the x position based on the current value
        let xPosition = -sliderWidth/2 + sliderWidth * value
        knobNode.position = CGPoint(x: xPosition, y: 0)
    }
    
    // Set volume programmatically
    func setVolume(_ newVolume: CGFloat, animated: Bool = false) {
        // Ensure value is between 0 and 1
        value = max(0, min(1, newVolume))
        
        if animated {
            // Animate knob position
            let newPosition = -sliderWidth/2 + sliderWidth * value
            let moveAction = SKAction.moveTo(x: newPosition, duration: 0.2)
            knobNode.run(moveAction)
        } else {
            // Update position immediately
            updateKnobPosition()
        }
        
        // Trigger callback
        onVolumeChange?(value)
    }
    
    // Get current volume value
    func getVolume() -> CGFloat {
        return value
    }
    
    // MARK: - Mouse Interaction
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        if knobNode.contains(location) {
            isDragging = true
        } else if trackNode.contains(location) {
            // If clicked on the track, move knob to that position
            updateVolumeFromMouseLocation(location)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        if isDragging {
            updateVolumeFromMouseLocation(event.location(in: self))
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }
    
    private func updateVolumeFromMouseLocation(_ location: CGPoint) {
        // Calculate the new value based on the x position
        let minX = -sliderWidth/2
        let maxX = sliderWidth/2
        
        // Clamp the x position between the track bounds
        let clampedX = max(minX, min(maxX, location.x))
        
        // Convert to 0-1 value
        value = (clampedX - minX) / sliderWidth
        
        // Update knob position
        updateKnobPosition()
        
        // Call the callback
        onVolumeChange?(value)
    }
}
