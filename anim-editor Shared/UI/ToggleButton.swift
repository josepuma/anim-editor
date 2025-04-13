//
//  ToggleButton.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

class ToggleButton: SKNode {
    // Visual components
    private let buttonNode: SKShapeNode
    private var iconNode: SKSpriteNode

    // State tracking
    private var isToggled = false
    private var onIconName: String
    private var offIconName: String
    private var buttonSize: CGFloat

    // Style properties
    private var buttonColor: SKColor
    private var buttonBorderColor: SKColor
    private var iconColor: SKColor
    private var iconSize: CGFloat

    // Callback for toggle events
    var onToggle: ((Bool) -> Void)?

    init(
        size: CGFloat = 32,
        onIconName: String = "check_on",  // Nombre del PNG sin extensión
        offIconName: String = "check_off", // Nombre del PNG sin extensión
        isInitiallyToggled: Bool = false,
        buttonColor: SKColor = SKColor(white: 0.2, alpha: 0.7),
        buttonBorderColor: SKColor = SKColor(white: 0.8, alpha: 0.8),
        iconColor: SKColor = .white,
        iconSize: CGFloat? = nil
    ) {
        self.buttonSize = size
        self.onIconName = onIconName
        self.offIconName = offIconName
        self.isToggled = isInitiallyToggled
        self.buttonColor = buttonColor
        self.buttonBorderColor = buttonBorderColor
        self.iconColor = iconColor
        self.iconSize = iconSize ?? (size * 0.6)

        // Create the button background (circle by default)
        buttonNode = SKShapeNode(circleOfRadius: size / 2)
        buttonNode.fillColor = buttonColor
        buttonNode.strokeColor = buttonBorderColor
        buttonNode.lineWidth = 1.0

        // Create the icon
        let initialIconName = isInitiallyToggled ? onIconName : offIconName
        iconNode = IconManager.shared.getIcon(named: initialIconName, size: self.iconSize, color: iconColor)

        super.init()

        addChild(buttonNode)
        addChild(iconNode)

        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Handle mouse clicks
    override func mouseDown(with event: NSEvent) {
        toggleState()
    }

    // Toggle the button state
    func toggleState() {
        isToggled.toggle()

        // Update the icon
        updateIconForCurrentState()

        // Callback
        onToggle?(isToggled)

        // Visual effect
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
        buttonNode.run(SKAction.sequence([scaleDown, scaleUp]))
    }

    func setState(isToggled: Bool) {
        if self.isToggled != isToggled {
            self.isToggled = isToggled
            updateIconForCurrentState()
        }
    }

    private func updateIconForCurrentState() {
            let iconName = isToggled ? onIconName : offIconName
            
            // Obtener el nuevo icono
            let newIconNode = IconManager.shared.getIcon(
                named: iconName,
                size: iconSize,
                color: iconColor
            )
            
            // Actualizar propiedades del iconNode existente para mantener la misma referencia
            iconNode.removeFromParent()  // Eliminar el nodo actual
            iconNode = newIconNode      // Actualizar la referencia
            addChild(iconNode)          // Añadir el nuevo nodo
        }

    func getState() -> Bool {
        return isToggled
    }

    func setButtonColor(color: SKColor) {
        buttonColor = color
        buttonNode.fillColor = color
    }

    func setBorderColor(color: SKColor) {
        buttonBorderColor = color
        buttonNode.strokeColor = color
    }

    func setIconColor(color: SKColor) {
        iconColor = color
        updateIconForCurrentState()
    }

    func setIcons(on: String, off: String) {
        onIconName = on
        offIconName = off
        updateIconForCurrentState()
    }

    func setIconSize(size: CGFloat) {
        iconSize = size
        updateIconForCurrentState()
    }
}
