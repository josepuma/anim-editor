import AVFoundation
import SpriteKit

/// An optimized hit sound manager for rhythm games using SpriteKit
class HitSoundManager {
    // MARK: - Types
    
    enum HitSoundType: Int {
        case normal = 1      // 1 << 0
        case whistle = 2     // 1 << 1
        case finish = 4      // 1 << 2
        case clap = 8        // 1 << 3
        
        static func getTypes(from value: Int) -> [HitSoundType] {
            var types: [HitSoundType] = []
            
            if value == 0 {
                types.append(.normal)  // Default to normal if no type specified
                return types
            }
            
            if (value & HitSoundType.normal.rawValue) != 0 {
                types.append(.normal)
            }
            if (value & HitSoundType.whistle.rawValue) != 0 {
                types.append(.whistle)
            }
            if (value & HitSoundType.finish.rawValue) != 0 {
                types.append(.finish)
            }
            if (value & HitSoundType.clap.rawValue) != 0 {
                types.append(.clap)
            }
            
            return types
        }
    }
    
    enum SoundSampleSet: Int {
        case auto = 0    // Default/inherit from timing point
        case normal = 1
        case soft = 2
        case drum = 3
        
        var name: String {
            switch self {
            case .auto: return "normal" // Fall back to normal when auto
            case .normal: return "normal"
            case .soft: return "soft"
            case .drum: return "drum"
            }
        }
        
        static func fromString(_ string: String) -> SoundSampleSet {
            if let value = Int(string) {
                switch value {
                case 0: return .auto
                case 1: return .normal
                case 2: return .soft
                case 3: return .drum
                default: return .auto
                }
            }
            return .auto
        }
    }
    
    // Struct para almacenar información completa de hitsounds
    struct HitSampleInfo {
        var normalSet: SoundSampleSet = .auto
        var additionSet: SoundSampleSet = .auto
        var index: Int = 0
        var volume: Int = 0
        var filename: String = ""
        
        init(fromString str: String = "0:0:0:0:") {
            let parts = str.split(separator: ":")
            if parts.count >= 1 { normalSet = SoundSampleSet.fromString(String(parts[0])) }
            if parts.count >= 2 { additionSet = SoundSampleSet.fromString(String(parts[1])) }
            if parts.count >= 3 { index = Int(parts[2]) ?? 0 }
            if parts.count >= 4 { volume = Int(parts[3]) ?? 0 }
            if parts.count >= 5 { filename = String(parts[4]) }
        }
    }
    
    // MARK: - Properties
    private let parentNode: SKNode
    private var audioNodePool: [String: [SKAudioNode]] = [:]
    private let poolSize = 8
    private let soundsPath: String
    private var defaultSampleSet: SoundSampleSet = .normal
    private var globalVolume: Float = 0.5
    private var layeredHitSounds: Bool = true // Siempre incluir normal sound (por defecto)
    
    // MARK: - Initialization
    init(soundsPath: String, parentNode: SKNode) {
        self.soundsPath = soundsPath
        self.parentNode = parentNode
        precacheHitSounds()
    }
    
    // MARK: - Sound Management
    private func precacheHitSounds() {
        // Precargar todas las combinaciones comunes
        let sampleSets = ["normal", "soft", "drum"]
        let hitSoundTypes = ["hitnormal", "hitwhistle", "hitfinish", "hitclap"]
        let indices = [0, 1, 2]  // Índices más comunes
        
        for sampleSet in sampleSets {
            for hitSound in hitSoundTypes {
                for index in indices {
                    let soundName = index > 0 ? "\(sampleSet)-\(hitSound)\(index)" : "\(sampleSet)-\(hitSound)"
                    createAudioNodePool(for: soundName)
                }
            }
        }
    }
    
    private func createAudioNodePool(for soundName: String) {
        // Verificar si el archivo existe
        let fullPath = "\(soundsPath)/\(soundName).wav"
        guard FileManager.default.fileExists(atPath: fullPath) else {
            return
        }
        
        var nodePool: [SKAudioNode] = []
        
        for _ in 0..<poolSize {
            if let audioNode = createAudioNode(named: soundName) {
                audioNode.autoplayLooped = false
                audioNode.isPositional = false
                nodePool.append(audioNode)
                parentNode.addChild(audioNode)
                audioNode.run(SKAction.stop())
            }
        }
        
        if !nodePool.isEmpty {
            audioNodePool[soundName] = nodePool
        }
    }
    
    private func createAudioNode(named soundName: String) -> SKAudioNode? {
        let fullPath = "\(soundsPath)/\(soundName).wav"
        
        do {
            let url = URL(fileURLWithPath: fullPath)
            let audioNode = SKAudioNode(url: url)
            audioNode.name = soundName
            audioNode.run(SKAction.changeVolume(to: globalVolume, duration: 0))
            return audioNode
        } catch {
            return nil
        }
    }
    
    // MARK: - Sound Playback API
    
    // Método principal para reproducir hitsounds con toda la información
    func playHitSound(hitsoundType: Int, sampleInfo: HitSampleInfo? = nil) {
        let hitSoundTypes = HitSoundType.getTypes(from: hitsoundType)
        
        // Si no hay tipos específicos y layeredHitSounds está activo, siempre incluir el normal
        if hitSoundTypes.isEmpty && layeredHitSounds {
            playSpecificSound(.normal, sampleInfo: sampleInfo)
        }
        
        // Reproducir cada tipo de sonido
        for type in hitSoundTypes {
            playSpecificSound(type, sampleInfo: sampleInfo)
        }
    }
    
    // Método para reproducir un tipo específico de sonido
    // En HitSoundManager.swift, modificar el método playSpecificSound:
    private func playSpecificSound(_ type: HitSoundType, sampleInfo: HitSampleInfo? = nil, timingPoint: TimingPoint? = nil) {
        // Determinar el sample set a usar
        let info = sampleInfo ?? HitSampleInfo()
        
        // Para sonidos normales, usar normalSet o timing point si es auto (0)
        let normalSampleSet: SoundSampleSet
        if info.normalSet == .auto {
            if let timingPoint = timingPoint {
                normalSampleSet = SoundSampleSet(rawValue: timingPoint.sampleSet) ?? defaultSampleSet
            } else {
                normalSampleSet = defaultSampleSet
            }
        } else {
            normalSampleSet = info.normalSet
        }
        
        // Para sonidos adicionales, usar additionSet o normalSet si es auto (0)
        let additionalSampleSet: SoundSampleSet
        if info.additionSet == .auto {
            additionalSampleSet = normalSampleSet // Hereda del normal set
        } else {
            additionalSampleSet = info.additionSet
        }
        
        // El sample set final dependiendo del tipo de sonido
        let sampleSet = type == .normal ? normalSampleSet : additionalSampleSet
        
        // Determinar el índice a usar
        let sampleIndex = info.index > 0 ? info.index : (timingPoint?.sampleIndex ?? 0)
        
        // Determinar el volumen a usar
        let sampleVolume = info.volume > 0 ? Float(info.volume) / 100.0 :
                          (timingPoint != nil ? Float(timingPoint!.volume) / 100.0 : globalVolume)
        
        // Construir el nombre del archivo
        var filename: String
        
        // Si se especificó un archivo personalizado, usarlo para adicionales
        if type != .normal && !info.filename.isEmpty {
            filename = info.filename
        } else {
            // Construir nombre según la convención osu
            let typeName: String
            switch type {
            case .normal: typeName = "hitnormal"
            case .whistle: typeName = "hitwhistle"
            case .finish: typeName = "hitfinish"
            case .clap: typeName = "hitclap"
            }
            
            // Incluir el índice si es mayor que 0
            let indexSuffix = sampleIndex > 0 ? "\(sampleIndex)" : ""
            filename = "\(sampleSet.name)-\(typeName)\(indexSuffix)"
        }
        
        // Reproducir el sonido con el volumen adecuado
        playSound(named: filename, volume: sampleVolume)
    }
    
    func playHitSound(hitsoundType: Int, sampleInfo: HitSampleInfo? = nil, timingPoint: TimingPoint? = nil) {
        let hitSoundTypes = HitSoundType.getTypes(from: hitsoundType)
        
        // Si no hay tipos específicos y layeredHitSounds está activo, siempre incluir el normal
        if hitSoundTypes.isEmpty && layeredHitSounds {
            playSpecificSound(.normal, sampleInfo: sampleInfo, timingPoint: timingPoint)
        }
        
        // Reproducir cada tipo de sonido
        for type in hitSoundTypes {
            playSpecificSound(type, sampleInfo: sampleInfo, timingPoint: timingPoint)
        }
    }
    
    // Método para reproducir un archivo de sonido específico
    private func playSound(named soundName: String, volume: Float) {
        guard let nodePool = audioNodePool[soundName], !nodePool.isEmpty else {
            // Si el sonido no está precargado, intentar cargarlo bajo demanda
            if let newNode = createAudioNode(named: soundName) {
                newNode.run(SKAction.changeVolume(to: volume, duration: 0))
                newNode.run(SKAction.play())
            }
            return
        }
        
        // Encontrar un nodo disponible
        var nodeToUse = nodePool.first { $0.action(forKey: "playing") == nil }
        if nodeToUse == nil {
            nodeToUse = nodePool.first
        }
        
        if let node = nodeToUse {
            node.run(SKAction.stop())
            node.run(SKAction.changeVolume(to: volume, duration: 0))
            let playAction = SKAction.play()
            node.run(playAction, withKey: "playing")
        }
    }
    
    // MARK: - Configuration
    func setDefaultSampleSet(_ sampleSet: SoundSampleSet) {
        self.defaultSampleSet = sampleSet
    }
    
    var volume: Float {
        get { return globalVolume }
        set {
            globalVolume = newValue
            for nodeArray in audioNodePool.values {
                for node in nodeArray {
                    node.run(SKAction.changeVolume(to: globalVolume, duration: 0))
                }
            }
        }
    }
    
    func setLayeredHitSounds(_ enabled: Bool) {
        layeredHitSounds = enabled
    }
    
    // MARK: - Cleanup
    func cleanup() {
        for nodeArray in audioNodePool.values {
            for node in nodeArray {
                node.removeFromParent()
            }
        }
        audioNodePool.removeAll()
    }
}
