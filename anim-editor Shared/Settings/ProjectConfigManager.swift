//
//  ProjectConfigManager.swift
//  anim-editor
//
//  Created by José Puma on 27-04-25.
//


import Foundation

class ProjectConfigManager {
    private var config: ProjectConfig
    private let configFilePath: String
    private let scriptsFolder: String  // Nueva propiedad para la carpeta de scripts
    
    init(projectPath: String, projectName: String = "Untitled Project") {
        self.configFilePath = projectPath + "/project_config.json"
        self.scriptsFolder = projectPath + "/scripts"  // Guardar referencia a la carpeta de scripts
        
        // Crear un valor temporal para config
        self.config = ProjectConfig(projectName: projectName)
        
        // Ahora que todas las propiedades están inicializadas,
        // podemos cargar la configuración
        if let loadedConfig = self.loadConfig() {
            self.config = loadedConfig
            
            // Actualizar con scripts existentes que no estén en la configuración
            self.syncWithExistingScripts()
        } else {
            // Si no hay configuración, inicializar con los scripts existentes
            self.initializeWithExistingScripts()
            self.saveConfig()
        }
    }
    
    // Método para sincronizar con scripts existentes
    private func syncWithExistingScripts() {
        // Obtener los scripts actuales en la carpeta
        let currentScripts = getScriptsInFolder()
        
        // Encontrar scripts nuevos (en la carpeta pero no en la configuración)
        let configScriptNames = Set(config.scripts.map { $0.name })
        let newScripts = currentScripts.filter { !configScriptNames.contains($0) }
        
        // Añadir scripts nuevos a la configuración
        for scriptName in newScripts {
            let zIndex = config.scripts.count + 1
            let newScript = ScriptConfig(name: scriptName, enabled: true, zIndex: zIndex)
            config.scripts.append(newScript)
        }
        
        // Eliminar scripts de la configuración que ya no existen en la carpeta
        config.scripts.removeAll { !currentScripts.contains($0.name) }
        
        // Si se hicieron cambios, guardar la configuración
        if !newScripts.isEmpty || configScriptNames.count != config.scripts.count {
            saveConfig()
        }
    }
    
    // Método para inicializar con scripts existentes
    private func initializeWithExistingScripts() {
        let currentScripts = getScriptsInFolder()
        
        // Crear configuración para cada script encontrado
        for (index, scriptName) in currentScripts.enumerated() {
            let script = ScriptConfig(name: scriptName, enabled: true, zIndex: index + 1)
            config.scripts.append(script)
        }
    }
    
    // Método para obtener los scripts en la carpeta
    private func getScriptsInFolder() -> [String] {
        let fileManager = FileManager.default
        var scriptNames: [String] = []
        
        do {
            if fileManager.fileExists(atPath: scriptsFolder) {
                let fileURLs = try fileManager.contentsOfDirectory(
                    at: URL(fileURLWithPath: scriptsFolder),
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                )
                
                for fileURL in fileURLs {
                    if fileURL.pathExtension.lowercased() == "js" {
                        let fileName = fileURL.deletingPathExtension().lastPathComponent
                        scriptNames.append(fileName)
                    }
                }
            }
        } catch {
            print("Error leyendo directorio de scripts: \(error)")
        }
        
        return scriptNames
    }
    
    // Método para escanear la carpeta de scripts en busca de cambios
    func checkForChanges() {
        syncWithExistingScripts()
    }
    
    private func loadConfig() -> ProjectConfig? {
        do {
            let fileManager = FileManager.default
            
            // Verificar si existe el archivo
            guard fileManager.fileExists(atPath: configFilePath) else {
                print("Archivo de configuración no encontrado, se creará uno nuevo")
                return nil
            }
            
            // Leer datos del archivo
            let data = try Data(contentsOf: URL(fileURLWithPath: configFilePath))
            
            // Configurar decoder con formato de fecha consistente
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Decodificar datos
            let config = try decoder.decode(ProjectConfig.self, from: data)
            print("✅ Configuración cargada correctamente")
            return config
            
        } catch {
            print("❌ Error cargando configuración: \(error)")
            return nil
        }
    }
    
    func saveConfig() {
        do {
            // Actualizar la fecha de última modificación
            config.lastModified = Date()
            
            // Configurar encoder con formato de fecha consistente
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            // Codificar datos
            let data = try encoder.encode(config)
            
            // Escribir al archivo
            try data.write(to: URL(fileURLWithPath: configFilePath))
            print("✅ Configuración guardada correctamente")
            
        } catch {
            print("❌ Error guardando configuración: \(error)")
        }
    }
    
    // MÉTODOS PARA ACCEDER/MODIFICAR LA CONFIGURACIÓN
    
    // Información general del proyecto
    func getProjectName() -> String {
        return config.projectName
    }
    
    func setProjectName(_ name: String) {
        config.projectName = name
        saveConfig()
    }
    
    func getProjectDescription() -> String {
        return config.description
    }
    
    func setProjectDescription(_ description: String) {
        config.description = description
        saveConfig()
    }
    
    // Manejo de scripts
    func getScripts() -> [ScriptConfig] {
        return config.scripts
    }
    
    func updateScriptOrder(newOrder: [String]) {
        // Crear nuevo array en el orden especificado
        let updatedScripts = newOrder.compactMap { scriptName in
            config.scripts.first { $0.name == scriptName }
        }
        
        // Añadir cualquier script que esté en la config pero no en el nuevo orden
        let existingNames = newOrder
        let missingScripts = config.scripts.filter { !existingNames.contains($0.name) }
        
        // Actualizar la config con el nuevo orden
        config.scripts = updatedScripts + missingScripts
        
        // Actualizar los índices Z
        for (index, script) in config.scripts.enumerated() {
            var updatedScript = script
            updatedScript.zIndex = index + 1  // Empezar desde 1
            config.scripts[index] = updatedScript
        }
        
        saveConfig()
    }
    
    func addOrUpdateScript(name: String, enabled: Bool = true) {
        // Verificar si el script ya existe
        if let index = config.scripts.firstIndex(where: { $0.name == name }) {
            // Actualizar script existente
            config.scripts[index].enabled = enabled
        } else {
            // Calcular zIndex para nuevo script
            let zIndex = config.scripts.count + 1
            
            // Añadir nuevo script
            let newScript = ScriptConfig(name: name, enabled: enabled, zIndex: zIndex)
            config.scripts.append(newScript)
        }
        
        saveConfig()
    }
    
    func removeScript(name: String) {
        config.scripts.removeAll { $0.name == name }
        saveConfig()
    }
    
    // Configuración de scripts específicos
    func getScriptSettings(name: String) -> [String: Any]? {
        guard let script = config.scripts.first(where: { $0.name == name }) else {
            return nil
        }
        
        return script.settings.mapValues { $0.value }
    }
    
    func updateScriptSetting(scriptName: String, key: String, value: Any) {
        guard let index = config.scripts.firstIndex(where: { $0.name == scriptName }) else {
            print("⚠️ Script no encontrado: \(scriptName)")
            return
        }
        
        config.scripts[index].settings[key] = AnyCodable(value)
        saveConfig()
    }
    
    // Preferencias del proyecto
    func getPreferences() -> ProjectPreferences {
        return config.preferences
    }
    
    func updatePreference<T>(key: String, value: T) {
        let mirror = Mirror(reflecting: config.preferences)
        
        for child in mirror.children {
            if child.label == key {
                // Usar keyPath para actualizar preferencias de forma segura
                if let keyPath = getKeyPath(for: key, in: ProjectPreferences.self) {
                    if let typedValue = value as? Any {
                        // Esta reflexión es algo simplificada y podría mejorarse
                        var preferences = config.preferences
                        setValue(&preferences, keyPath: keyPath, newValue: typedValue)
                        config.preferences = preferences
                        saveConfig()
                    }
                }
                break
            }
        }
    }
    
    // Método auxiliar para obtener un KeyPath basado en una cadena
    private func getKeyPath<T>(for key: String, in type: T.Type) -> AnyKeyPath? {
        switch key {
        case "defaultGridVisible":
            return \ProjectPreferences.defaultGridVisible
        case "defaultVolume":
            return \ProjectPreferences.defaultVolume
        case "lastOpenedTime":
            return \ProjectPreferences.lastOpenedTime
        default:
            return nil
        }
    }
    
    // Método auxiliar para establecer un valor usando keypath
    private func setValue<T>(_ object: inout T, keyPath: AnyKeyPath, newValue: Any) {
        // Este método es simplificado y solo maneja algunos tipos
        if let keyPath = keyPath as? WritableKeyPath<T, Bool>, let value = newValue as? Bool {
            object[keyPath: keyPath] = value
        } else if let keyPath = keyPath as? WritableKeyPath<T, Double>, let value = newValue as? Double {
            object[keyPath: keyPath] = value
        } else if let keyPath = keyPath as? WritableKeyPath<T, String>, let value = newValue as? String {
            object[keyPath: keyPath] = value
        } else if let keyPath = keyPath as? WritableKeyPath<T, Date?>, let value = newValue as? Date {
            object[keyPath: keyPath] = value
        }
    }
}
