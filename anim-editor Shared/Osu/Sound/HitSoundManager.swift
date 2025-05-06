import AVFoundation
import SpriteKit

/// An optimized hit sound manager for rhythm games using SpriteKit
class HitSoundManager {
    // MARK: - Types
    
    /// Types of hit sounds in OSU
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
    
    /// Sample sets for sounds
    enum SoundSampleSet: Int {
        case normal = 1
        case soft = 2
        case drum = 3
        
        static func fromString(_ string: String) -> SoundSampleSet {
            if let value = Int(string) {
                switch value {
                case 1: return .normal
                case 2: return .soft
                case 3: return .drum
                default: return .normal
                }
            }
            return .normal
        }
    }
    
    // MARK: - Properties
    
    /// The parent node to attach audio nodes to
    private weak var parentNode: SKNode?
    
    /// Cache of pre-loaded audio nodes
    private var audioNodePool: [String: [SKAudioNode]] = [:]
    
    /// Maximum nodes per sound type
    private let poolSize = 8
    
    /// Path to the sounds directory
    private let soundsPath: String
    
    /// Default sample set to use
    private var defaultSampleSet: SoundSampleSet = .normal
    
    /// Volume for hit sounds (0.0 to 1.0)
    var volume: Float = 0.3 {
        didSet {
            // Update volume for all cached nodes
            for nodeArray in audioNodePool.values {
                for audioNode in nodeArray {
                    audioNode.run(SKAction.changeVolume(to: volume, duration: 0))
                }
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize the hit sound manager
    /// - Parameters:
    ///   - soundsPath: Path to the directory containing the hit sounds
    ///   - parentNode: The parent node to attach audio nodes to
    init(soundsPath: String, parentNode: SKNode) {
        self.soundsPath = soundsPath
        self.parentNode = parentNode
        
        // Preload sound pools
        precacheHitSounds()
    }
    
    // MARK: - Sound Management
    
    /// Preload all the required hit sounds
    private func precacheHitSounds() {
        // Standard sound combinations
        let sampleSets = ["normal", "soft", "drum"]
        let hitSoundTypes = ["hitnormal", "hitwhistle", "hitfinish", "hitclap"]
        
        for sampleSet in sampleSets {
            for hitSound in hitSoundTypes {
                let soundName = "\(sampleSet)-\(hitSound)"
                createAudioNodePool(for: soundName)
            }
        }
    }
    
    /// Create a pool of reusable audio nodes for a specific sound
    /// - Parameter soundName: Name of the sound file (without extension)
    private func createAudioNodePool(for soundName: String) {
        // Check if file exists
        let fullPath = "\(soundsPath)/\(soundName).wav"
        guard FileManager.default.fileExists(atPath: fullPath) else {
            print("⚠️ Sound file not found: \(fullPath)")
            return
        }
        
        // Create the pool
        var nodePool: [SKAudioNode] = []
        
        for _ in 0..<poolSize {
            if let audioNode = createAudioNode(named: soundName) {
                // Set initial properties
                audioNode.autoplayLooped = false
                audioNode.isPositional = false // Disable 3D audio for hit sounds
                
                // Store in pool
                nodePool.append(audioNode)
                
                // Add to parent but stop it immediately
                parentNode?.addChild(audioNode)
                audioNode.run(SKAction.stop())
            }
        }
        
        if !nodePool.isEmpty {
            audioNodePool[soundName] = nodePool
            print("✅ Precached sound pool: \(soundName) (\(nodePool.count) nodes)")
        }
    }
    
    /// Create a single audio node
    /// - Parameter soundName: Name of the sound file (without extension)
    /// - Returns: An initialized SKAudioNode or nil if creation fails
    private func createAudioNode(named soundName: String) -> SKAudioNode? {
        let fullPath = "\(soundsPath)/\(soundName).wav"
        
        do {
            // Instead of loading directly from file, use URL to avoid path issues
            let url = URL(fileURLWithPath: fullPath)
            let audioNode = SKAudioNode(url: url)
            audioNode.name = soundName
            
            // Set initial volume
            audioNode.run(SKAction.changeVolume(to: volume, duration: 0))
            
            return audioNode
        } catch {
            print("❌ Error creating audio node: \(error)")
            return nil
        }
    }
    
    // MARK: - Sound Playback
    
    /// Play hit sounds based on the hit type and sample set
    /// - Parameters:
    ///   - hitsoundType: Bitwise flags indicating which hit sounds to play
    ///   - sampleSet: The sample set to use (optional)
    func playHitSound(hitsoundType: Int, sampleSet: SoundSampleSet? = nil) {
        let actualSampleSet = sampleSet ?? defaultSampleSet
        let sampleSetName: String
        
        switch actualSampleSet {
        case .normal: sampleSetName = "normal"
        case .soft: sampleSetName = "soft"
        case .drum: sampleSetName = "drum"
        }
        
        let hitSoundTypes = HitSoundType.getTypes(from: hitsoundType)
        
        for type in hitSoundTypes {
            var soundName = ""
            
            switch type {
            case .normal: soundName = "\(sampleSetName)-hitnormal"
            case .whistle: soundName = "\(sampleSetName)-hitwhistle"
            case .finish: soundName = "\(sampleSetName)-hitfinish"
            case .clap: soundName = "\(sampleSetName)-hitclap"
            }
            
            playPooledSound(name: soundName)
        }
    }
    
    /// Play a sound using the node pool
    /// - Parameter name: Name of the sound to play
    private func playPooledSound(name: String) {
            guard let nodePool = audioNodePool[name], !nodePool.isEmpty else {
                print("⚠️ No audio nodes available for: \(name)")
                return
            }
            
            // Find an available node (one that's not playing)
            var nodeToUse: SKAudioNode? = nil
            
            // Try to find a node that doesn't have a playing action
            for node in nodePool {
                if node.action(forKey: "playing") == nil {
                    nodeToUse = node
                    break
                }
            }
            
            // If no available node found, just take the first one
            if nodeToUse == nil {
                nodeToUse = nodePool.first
            }
            
            // Play the sound
            if let node = nodeToUse {
                // First stop any currently playing sound
                node.run(SKAction.stop())
                
                // Then play the sound with a unique key
                let playAction = SKAction.play()
                node.run(playAction, withKey: "playing")
            }
        }
    
    /// Set the default sample set
    /// - Parameter sampleSet: The sample set to use
    func setDefaultSampleSet(_ sampleSet: SoundSampleSet) {
        self.defaultSampleSet = sampleSet
    }
    
    /// Update this in the scene's update method
    func update() {
        // Perform any per-frame updates if needed
    }
    
    /// Clean up resources
    func cleanup() {
        // Remove all audio nodes from parent
        for nodeArray in audioNodePool.values {
            for node in nodeArray {
                node.removeFromParent()
            }
        }
        
        // Clear the cache
        audioNodePool.removeAll()
    }
}
