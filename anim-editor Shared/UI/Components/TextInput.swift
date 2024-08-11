import SpriteKit
import AppKit

class TextInput: SKNode {
    private var textField: NSTextField!
    private var backgroundNode: SKShapeNode!

    init(size: CGSize) {
        super.init()
        
        self.isUserInteractionEnabled = true

        // Create and configure the background node
        backgroundNode = SKShapeNode(rectOf: size, cornerRadius: 5)
        backgroundNode.fillColor = .white
        backgroundNode.strokeColor = .gray
        addChild(backgroundNode)

        // Create and configure the NSTextField
        textField = NSTextField(frame: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.alignment = .center
        textField.lineBreakMode = .byTruncatingTail
        textField.cell?.usesSingleLineMode = true
        textField.cell?.wraps = false

        // Ensure the text field's frame matches the background node's frame
        // This is important to call after adding the node to the view
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setupTextField(in view: SKView) {
        view.addSubview(textField)
        updateTextFieldPosition()
        updateTextFieldFrame()
    }

    func updateTextFieldPosition() {
        if let scene = self.scene, let skView = scene.view {
            let positionInView = skView.convert(self.position, from: scene)
            textField.frame.origin = CGPoint(
                x: positionInView.x - backgroundNode.frame.width / 2,
                y: positionInView.y - backgroundNode.frame.height / 2
            )
        }
    }

    func updateTextFieldFrame() {
        // Adjust text field frame to match backgroundNode
        textField.frame = NSRect(
            x: 0,
            y: 0,
            width: backgroundNode.frame.width,
            height: backgroundNode.frame.height
        )
        textField.setNeedsDisplay(textField.bounds)
    }

    var text: String {
        get {
            return textField.stringValue
        }
        set {
            textField.stringValue = newValue
        }
    }

    override var position: CGPoint {
        didSet {
            updateTextFieldPosition()
        }
    }

    override func removeFromParent() {
        textField.removeFromSuperview()
        super.removeFromParent()
    }

    override func mouseDown(with event: NSEvent) {
        textField.becomeFirstResponder()
    }
}
