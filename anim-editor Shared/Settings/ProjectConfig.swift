//
//  ProjectConfig.swift
//  anim-editor
//
//  Created by José Puma on 27-04-25.
//
import Foundation

struct ProjectConfig: Codable {
    var audioPath: String
    var projectName: String
    var description: String
    var created: Date
    var lastModified: Date
    var version: String
    var scripts: [ScriptConfig]
    var preferences: ProjectPreferences
    
    // Constructor con valores por defecto
    init(projectName: String, description: String = "") {
        self.projectName = projectName
        self.description = description
        self.created = Date()
        self.lastModified = Date()
        self.version = "1.0"
        self.audioPath = ""
        self.scripts = []
        self.preferences = ProjectPreferences()
    }
}

struct ScriptConfig: Codable {
    var name: String
    var enabled: Bool
    var zIndex: Int
    var settings: [String: AnyCodable]
    
    init(name: String, enabled: Bool = true, zIndex: Int = 0) {
        self.name = name
        self.enabled = enabled
        self.zIndex = zIndex
        self.settings = [:]
    }
}

struct ProjectPreferences: Codable {
    var defaultGridVisible: Bool
    var defaultVolume: Double
    var lastOpenedTime: Date?
    
    init(defaultGridVisible: Bool = false, defaultVolume: Double = 0.5) {
        self.defaultGridVisible = defaultGridVisible
        self.defaultVolume = defaultVolume
        self.lastOpenedTime = nil
    }
}

// Wrapper para permitir cualquier tipo de valor en JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath,
                                               debugDescription: "AnyCodable cannot encode value")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}
