//
//  SliderCurveType.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

enum SliderCurveType: String {
    case linear = "L"
    case catmull = "C" // Catmull curve
    case bezier = "B"  // Bezier curve
    case perfect = "P" // Perfect circle
    
    static func fromString(_ string: String) -> SliderCurveType {
        switch string {
        case "L": return .linear
        case "C": return .catmull
        case "B": return .bezier
        case "P": return .perfect
        default: return .linear
        }
    }
}
