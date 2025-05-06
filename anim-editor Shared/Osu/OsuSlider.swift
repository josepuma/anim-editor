//
//  OsuSlider.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

import SpriteKit

class OsuSlider: OsuHitObject {
    var curveType: SliderCurveType
    var curvePoints: [OsuPoint]
    var slides: Int
    var length: Double
    var edgeSounds: [Int]
    var edgeSets: [String]
    
    init(position: OsuPoint, time: Int, type: OsuHitObjectType, newCombo: Bool, comboColorOffset: Int, hitsoundType: Int, curveType: SliderCurveType, curvePoints: [OsuPoint], slides: Int, length: Double, edgeSounds: [Int], edgeSets: [String]) {
        self.curveType = curveType
        self.curvePoints = curvePoints
        self.slides = slides
        self.length = length
        self.edgeSounds = edgeSounds
        self.edgeSets = edgeSets
        
        super.init(position: position, time: time, type: type, newCombo: newCombo, comboColorOffset: comboColorOffset, hitsoundType: hitsoundType)
    }
    
    // Generar un path basado en los puntos de control y el tipo de curva
    func generateSliderPath() -> CGPath {
        let path = CGMutablePath()
        
        // Convertir punto inicial
        let startPoint = position.toSpriteKitPosition(width: 640, height: 480)
        path.move(to: startPoint)
        
        // Necesitamos al menos un punto de control para cualquier curva
        guard !curvePoints.isEmpty else {
            return path
        }
        
        switch curveType {
        case .linear:
            // Para sliders lineales, simplemente conectamos los puntos
            for point in curvePoints {
                let convertedPoint = point.toSpriteKitPosition(width: 640, height: 480)
                path.addLine(to: convertedPoint)
            }
            
        case .bezier:
            // Para curvas Bezier necesitamos agrupar los puntos de control
            var currentPoints: [CGPoint] = [startPoint]
            
            for point in curvePoints {
                let convertedPoint = point.toSpriteKitPosition(width: 640, height: 480)
                currentPoints.append(convertedPoint)
                
                // Cada segmento de Bezier necesita múltiplos de 3 puntos de control + 1 punto inicial
                if currentPoints.count == 4 { // 1 punto inicial + 3 puntos de control
                    // Crear curva Bezier
                    path.addCurve(
                        to: currentPoints[3],
                        control1: currentPoints[1],
                        control2: currentPoints[2]
                    )
                    
                    // Iniciar nuevo segmento desde el último punto
                    currentPoints = [currentPoints.last!]
                }
            }
            
            // Si quedan puntos sin usar, tratarlos como una línea
            if currentPoints.count > 1 {
                for i in 1..<currentPoints.count {
                    path.addLine(to: currentPoints[i])
                }
            }
            
        case .catmull:
            // Implementar Catmull-Rom (una variación de curva spline)
            // Nota: Esto es una aproximación simplificada
            if curvePoints.count >= 3 {
                let controlPoints = [startPoint] + curvePoints.map { $0.toSpriteKitPosition(width: 640, height: 480) }
                
                for i in 0..<controlPoints.count - 3 {
                    let p0 = controlPoints[i]
                    let p1 = controlPoints[i + 1]
                    let p2 = controlPoints[i + 2]
                    let p3 = controlPoints[i + 3]
                    
                    // Calcular puntos de control "virtuales" para la interpolación Catmull-Rom
                    let cp1 = CGPoint(
                        x: p1.x + (p2.x - p0.x) / 6,
                        y: p1.y + (p2.y - p0.y) / 6
                    )
                    
                    let cp2 = CGPoint(
                        x: p2.x - (p3.x - p1.x) / 6,
                        y: p2.y - (p3.y - p1.y) / 6
                    )
                    
                    path.addCurve(to: p2, control1: cp1, control2: cp2)
                }
            } else {
                // Si no hay suficientes puntos, tratar como lineal
                for point in curvePoints {
                    let convertedPoint = point.toSpriteKitPosition(width: 640, height: 480)
                    path.addLine(to: convertedPoint)
                }
            }
            
        case .perfect:
            // Para curvas perfectas (círculos), necesitamos tres puntos que definan un círculo
            // El primer punto es nuestra posición inicial, más dos puntos de control
            if curvePoints.count >= 2 {
                let pointA = startPoint
                let pointB = curvePoints[0].toSpriteKitPosition(width: 640, height: 480)
                let pointC = curvePoints[1].toSpriteKitPosition(width: 640, height: 480)
                
                // Calcular el centro del círculo que pasa por estos tres puntos
                if let center = calculateCircleCenter(a: pointA, b: pointB, c: pointC) {
                    // Calcular el radio
                    let radius = sqrt(pow(pointA.x - center.x, 2) + pow(pointA.y - center.y, 2))
                    
                    // Calcular ángulos para los arcos
                    let startAngle = atan2(pointA.y - center.y, pointA.x - center.x)
                    let midAngle = atan2(pointB.y - center.y, pointB.x - center.x)
                    let endAngle = atan2(pointC.y - center.y, pointC.x - center.x)
                    
                    // Determinar si el arco debe ser en sentido horario o antihorario
                    var clockwise = false
                    
                    // Esta es una simplificación - en realidad habría que verificar varias condiciones
                    if (midAngle > startAngle && midAngle < endAngle) ||
                       (startAngle > endAngle && (midAngle > startAngle || midAngle < endAngle)) {
                        clockwise = false
                    } else {
                        clockwise = true
                    }
                    
                    // Añadir el arco al path
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: clockwise
                    )
                } else {
                    // Si no se puede calcular el centro, tratar como lineal
                    for point in curvePoints {
                        let convertedPoint = point.toSpriteKitPosition(width: 640, height: 480)
                        path.addLine(to: convertedPoint)
                    }
                }
            } else {
                // Si no hay suficientes puntos, tratar como lineal
                for point in curvePoints {
                    let convertedPoint = point.toSpriteKitPosition(width: 640, height: 480)
                    path.addLine(to: convertedPoint)
                }
            }
        }
        
        return path
    }
    
    // Función auxiliar para calcular el centro de un círculo dados tres puntos
    private func calculateCircleCenter(a: CGPoint, b: CGPoint, c: CGPoint) -> CGPoint? {
        // Calcular coordenadas auxiliares
        let d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
        
        // Si d es cero, los puntos son colineales y no forman un círculo
        if abs(d) < 0.0001 {
            return nil
        }
        
        let aSq = a.x * a.x + a.y * a.y
        let bSq = b.x * b.x + b.y * b.y
        let cSq = c.x * c.x + c.y * c.y
        
        let centerX = (aSq * (b.y - c.y) + bSq * (c.y - a.y) + cSq * (a.y - b.y)) / d
        let centerY = (aSq * (c.x - b.x) + bSq * (a.x - c.x) + cSq * (b.x - a.x)) / d
        
        return CGPoint(x: centerX, y: centerY)
    }
    
    override func createSprite(circleTexture: SKTexture, approachTexture: SKTexture) -> Sprite {
        // Para un slider, usaremos un nodo contenedor para agrupar
        // el path del slider y los círculos de inicio/fin
        
        // Usar la textura del círculo para el sprite principal
        let sprite = Sprite(texture: circleTexture)
        sprite.setInitialPosition(position: position.toSpriteKitPosition(width: 640, height: 480))
        
        // Duración del slider (simplificada)
        let sliderDuration = 500 * slides // milisegundos por repetición
        let endTime = time + sliderDuration
        
        // Animaciones para el círculo principal (igual que para OsuCircle)
        sprite.addFadeTween(easing: .sineOut,
                          startTime: time - 800,
                          endTime: time - 600,
                          startValue: 0,
                          endValue: 1)
        
        sprite.addScaleTween(easing: .sineOut,
                           startTime: time - 800,
                           endTime: time - 600,
                           startValue: 0.1,
                             endValue: 0.65)
        
        // Mantener visible durante el slider
        sprite.addFadeTween(easing: .linear,
                          startTime: time - 600,
                          endTime: endTime,
                          startValue: 1,
                          endValue: 1)
        
        // Desvanecer al finalizar
        sprite.addFadeTween(easing: .sineIn,
                          startTime: endTime,
                          endTime: endTime + 200,
                          startValue: 1,
                          endValue: 0)
        
        return sprite
    }
    
    // Crear un sprite independiente para el path del slider
    func createSliderPathSprite() -> Sprite {
        // Obtener la posición inicial en coordenadas SpriteKit
        let initialPosition = position.toSpriteKitPosition(width: 640, height: 480)
        
        // Generar el path pero trasladado para que comience en (0,0)
        let originalPath = generateSliderPath()
        var transform = CGAffineTransform(translationX: -initialPosition.x, y: -initialPosition.y)
        
        // Crear los dos paths para el slider
        // 1. Path para el borde (blanco, más ancho)
        let borderPathNode = SKShapeNode()
        if let transformedPath = originalPath.copy(using: &transform) {
            borderPathNode.path = transformedPath
        } else {
            borderPathNode.path = originalPath // Fallback
        }
        
        borderPathNode.lineWidth = 70 // Más ancho para el borde
        borderPathNode.strokeColor = .white // Borde blanco
        borderPathNode.fillColor = .clear
        borderPathNode.alpha = 0.8
        borderPathNode.lineCap = .round
        borderPathNode.lineJoin = .round
        
        // 2. Path para el relleno (negro, más delgado)
        let mainPathNode = SKShapeNode()
        if let transformedPath = originalPath.copy(using: &transform) {
            mainPathNode.path = transformedPath
        } else {
            mainPathNode.path = originalPath // Fallback
        }
        
        mainPathNode.lineWidth = 60 // Más delgado que el borde
        mainPathNode.strokeColor = .black // Relleno negro
        mainPathNode.fillColor = .clear
        mainPathNode.alpha = 0.8
        mainPathNode.lineCap = .round
        mainPathNode.lineJoin = .round
        
        // Crear una textura a partir del nodo de forma
        let size = CGSize(width: 640, height: 480)
        let renderer = SKView(frame: CGRect(origin: .zero, size: size))
        let renderScene = SKScene(size: size)
        renderScene.backgroundColor = .clear
        
        // Centrar los nodos en la escena de renderizado
        borderPathNode.position = CGPoint(x: size.width/2, y: size.height/2)
        mainPathNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        // Añadir primero el borde (para que esté detrás) y luego el path principal
        renderScene.addChild(borderPathNode)
        renderScene.addChild(mainPathNode)
        
        let texture = renderer.texture(from: renderScene) ?? SKTexture()
        
        // Crear el sprite del slider usando la textura renderizada
        let sprite = Sprite(texture: texture)
        sprite.setInitialPosition(position: initialPosition)
        
        // Duración del slider (simplificada)
        let sliderDuration = 500 * slides // milisegundos por repetición
        let endTime = time + sliderDuration
        
        // Animación de aparición
        sprite.addFadeTween(easing: .sineOut,
                          startTime: time - 800,
                          endTime: time - 600,
                          startValue: 0,
                          endValue: 1)
        
        // Mantener visible durante el slider
        sprite.addFadeTween(easing: .linear,
                          startTime: time - 600,
                          endTime: endTime,
                          startValue: 1,
                          endValue: 1)
        
        // Desvanecer al finalizar
        sprite.addFadeTween(easing: .sineIn,
                          startTime: endTime,
                          endTime: endTime + 200,
                          startValue: 1,
                          endValue: 0)
        
        return sprite
    }
}
