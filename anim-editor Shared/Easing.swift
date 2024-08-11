//
//  Created by José Puma on 23-02-24.
//
import SpriteKit

enum Easing : String, CaseIterable {
    case linear, easingOut, easingIn, quadIn, quadOut, quadInout, cubicIn, cubicOut, cubicInOut, quartIn, quartOut, quartInOut, quintIn,
    quinOut, quinInOut, sineIn, sineOut, sineInOut, expoIn, expoOut, expoInOut, circIn, circOut, circInOut, elasticIn, elasticOut, elasticHalfOut, elasticQuarterOut, elasticInOut, backIn, backOut, backInOut, bounceIn, bounceOut, bounceInOut
    
    func getEasingValue(progress: Double) -> Double{
        switch self {
        case .linear:
            return progress
        case .easingOut:
            return -progress * (progress - 2)
        case .easingIn:
            return progress * progress
        case .quadIn:
            return progress * progress
        case .quadOut:
            return progress
        case .quadInout:
            return progress
        case .cubicIn:
            return progress * progress * progress
        case .cubicOut:
            let p = progress - 1
            return p * p * p + 1
        case .cubicInOut:
            return progress
        case .quartIn:
            return progress
        case .quartOut:
            return progress
        case .quartInOut:
            return progress
        case .quintIn:
            return progress * progress * progress * progress * progress
        case .quinOut:
            return progress
        case .quinInOut:
            return progress
        case .sineIn:
            return 1 - cos(progress * Double.pi / 2)
        case .sineOut:
            return progress
        case .sineInOut:
            return progress
        case .expoIn:
            return progress
        case .expoOut:
            return progress
        case .expoInOut:
            return progress
        case .circIn:
            return 1 - sqrt(1 - progress * progress)
        case .circOut:
            return sqrt((2 - progress) * progress)
        case .circInOut:
            return progress
        case .elasticIn:
            return progress
        case .elasticOut:
            return progress
        case .elasticHalfOut:
            return progress
        case .elasticQuarterOut:
            return progress
        case .elasticInOut:
            return progress
        case .backIn:
            return progress
        case .backOut:
            return progress
        case .backInOut:
            return progress
        case .bounceIn:
            return progress
        case .bounceOut:
            return progress
        case .bounceInOut:
            return progress
        }
    }
}

extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}


