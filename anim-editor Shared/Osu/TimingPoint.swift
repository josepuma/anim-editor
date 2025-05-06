//
//  TimingPoint.swift
//  anim-editor
//
//  Created by José Puma on 06-05-25.
//

struct TimingPoint {
    var time: Int                  // Tiempo en milisegundos
    var beatLength: Double         // Duración del beat en ms
    var meter: Int                 // Número de beats por compás
    var sampleSet: Int             // 1=normal, 2=soft, 3=drum
    var sampleIndex: Int           // Índice de sample
    var volume: Int                // Volumen (0-100)
    var uninherited: Bool          // Si es un timing point original o heredado
    var effects: Int               // Efectos (bits de flag)
    
    init(fromString string: String) {
        let parts = string.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        time = Int(Double(parts[0]) ?? 0)
        beatLength = Double(parts[1]) ?? 0
        meter = parts.count > 2 ? Int(parts[2]) ?? 4 : 4
        sampleSet = parts.count > 3 ? Int(parts[3]) ?? 0 : 0
        sampleIndex = parts.count > 4 ? Int(parts[4]) ?? 0 : 0
        volume = parts.count > 5 ? Int(parts[5]) ?? 100 : 100
        uninherited = parts.count > 6 ? Int(parts[6]) ?? 1 == 1 : true
        effects = parts.count > 7 ? Int(parts[7]) ?? 0 : 0
    }
}
