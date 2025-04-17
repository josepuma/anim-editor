//
//  ParticleScriptManager.swift
//  anim-editor
//
//  Created by José Puma on 17-04-25.
//

import Foundation
import SpriteKit

/// Clase encargada de gestionar los scripts de efectos de partículas con ejecución automática
class ParticleScriptManager {
    // Intérprete JavaScript
    private let interpreter: JSInterpreter
    
    // Directorios de trabajo
    private let scriptsFolder: String
    private let templatesFolder: String
    
    // Scripts cargados
    private var availableScripts: [String] = []
    
    // Referencias necesarias
    private weak var particleManager: ParticleManager?
    private weak var scene: SKScene?
    
    // Timer para recarga automática de scripts
    private var autoReloadTimer: Timer?
    private var lastModificationDates: [String: Date] = [:]
    
    init(particleManager: ParticleManager, scene: SKScene, scriptsFolder: String) {
        self.particleManager = particleManager
        self.scene = scene
        self.scriptsFolder = scriptsFolder
        self.templatesFolder = scriptsFolder + "/templates"
        
        // Asegurarse de que existan las carpetas

        
        // Inicializar el intérprete
        self.interpreter = JSInterpreter(particleManager: particleManager, scene: scene)
        ensureDirectoriesExist()
        // Cargar y ejecutar scripts disponibles
        loadAndExecuteAllScripts()
        
        // Configurar timer para recarga automática
        setupAutoReloadTimer()
    }
    
    /// Asegura que existan los directorios necesarios
    private func ensureDirectoriesExist() {
        let fileManager = FileManager.default
        
        // Crear carpeta de scripts si no existe
        if !fileManager.fileExists(atPath: scriptsFolder) {
            do {
                try fileManager.createDirectory(
                    atPath: scriptsFolder,
                    withIntermediateDirectories: true
                )
            } catch {
                print("Error creando directorio de scripts: \(error)")
            }
        }
        
        // Crear carpeta de plantillas si no existe
        if !fileManager.fileExists(atPath: templatesFolder) {
            do {
                try fileManager.createDirectory(
                    atPath: templatesFolder,
                    withIntermediateDirectories: true
                )
                
                // Crear plantillas iniciales
                createTemplates()
            } catch {
                print("Error creando directorio de plantillas: \(error)")
            }
        }
    }
    
    /// Crea plantillas de scripts para usuarios
    private func createTemplates() {
        // Plantillas similares a las que ya teníamos...
        // [Aquí irían las plantillas que ya has definido]
    }
    
    /// Carga y ejecuta todos los scripts disponibles
    func loadAndExecuteAllScripts() {
        // Cargar scripts
        availableScripts = interpreter.loadScripts(fromFolder: scriptsFolder)
        
        // Registrar fechas de modificación
        updateModificationDates()
        
        // Ejecutar todos los scripts automáticamente
        for scriptName in availableScripts {
            executeScript(named: scriptName)
        }
        
        print("Se cargaron y ejecutaron \(availableScripts.count) scripts automáticamente")
    }
    
    /// Actualiza los registros de fechas de modificación de los scripts
    private func updateModificationDates() {
        let fileManager = FileManager.default
        
        for scriptName in availableScripts {
            let scriptPath = "\(scriptsFolder)/\(scriptName).js"
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: scriptPath)
                if let modDate = attributes[.modificationDate] as? Date {
                    lastModificationDates[scriptName] = modDate
                }
            } catch {
                print("Error obteniendo atributos de \(scriptPath): \(error)")
            }
        }
    }
    
    /// Configura un timer para revisar cambios en los scripts
    private func setupAutoReloadTimer() {
        // Revisar cada 5 segundos si hay cambios en los scripts
        autoReloadTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkForScriptChanges()
        }
    }
    
    /// Revisa si hay cambios en los scripts y los recarga si es necesario
    private func checkForScriptChanges() {
        let fileManager = FileManager.default
        
        // Verificar si hay scripts nuevos primero
        let currentScripts = getScriptFilesInFolder()
        let newScripts = currentScripts.filter { !availableScripts.contains($0) }
        
        if !newScripts.isEmpty {
            print("Se encontraron \(newScripts.count) scripts nuevos. Recargando todos los scripts...")
            loadAndExecuteAllScripts()
            return
        }
        
        // Verificar modificaciones en scripts existentes
        for scriptName in availableScripts {
            let scriptPath = "\(scriptsFolder)/\(scriptName).js"
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: scriptPath)
                if let modDate = attributes[.modificationDate] as? Date,
                   let lastModDate = lastModificationDates[scriptName],
                   modDate > lastModDate {
                    
                    print("Script modificado: \(scriptName), recargando...")
                    
                    // Recargar y ejecutar solo este script
                    if interpreter.loadScript(from: scriptPath) {
                        executeScript(named: scriptName)
                        lastModificationDates[scriptName] = modDate
                    }
                }
            } catch {
                print("Error verificando modificaciones de \(scriptPath): \(error)")
            }
        }
    }
    
    /// Obtiene la lista de scripts en la carpeta
    private func getScriptFilesInFolder() -> [String] {
        let fileManager = FileManager.default
        var scriptNames: [String] = []
        
        do {
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
        } catch {
            print("Error leyendo directorio de scripts: \(error)")
        }
        
        return scriptNames
    }
    
    /// Ejecuta un script específico
    func executeScript(named scriptName: String) -> Bool {
        print("⏳ Intentando ejecutar script: \(scriptName)")
        
        let result = interpreter.executeScript(named: scriptName)
        
        if result {
            print("✅ Script ejecutado correctamente: \(scriptName)")
        } else {
            print("❌ Fallo al ejecutar script: \(scriptName)")
        }
        
        return result
    }
    
    /// Crea un nuevo script basado en una plantilla
    func createNewScript(name: String, fromTemplate templateName: String) -> Bool {
        let templatePath = "\(templatesFolder)/\(templateName).js"
        let newScriptPath = "\(scriptsFolder)/\(name).js"
        
        let fileManager = FileManager.default
        
        // Verificar que no exista ya un script con ese nombre
        if fileManager.fileExists(atPath: newScriptPath) {
            print("Error: Ya existe un script con el nombre \(name)")
            return false
        }
        
        // Verificar que exista la plantilla
        guard fileManager.fileExists(atPath: templatePath) else {
            print("Error: Plantilla \(templateName) no encontrada")
            return false
        }
        
        do {
            // Copiar la plantilla
            try fileManager.copyItem(atPath: templatePath, toPath: newScriptPath)
            
            // Cargar y ejecutar el nuevo script
            if interpreter.loadScript(from: newScriptPath) {
                executeScript(named: name)
                
                // Actualizar lista de scripts y fechas
                if !availableScripts.contains(name) {
                    availableScripts.append(name)
                }
                
                // Registrar fecha de modificación
                let attributes = try fileManager.attributesOfItem(atPath: newScriptPath)
                if let modDate = attributes[.modificationDate] as? Date {
                    lastModificationDates[name] = modDate
                }
            }
            
            return true
        } catch {
            print("Error creando nuevo script: \(error)")
            return false
        }
    }
    
    /// Abre la carpeta de scripts
    func openScriptsFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: scriptsFolder))
    }
    
    /// Edita un script específico (abre con el editor predeterminado)
    func editScript(named scriptName: String) {
        let scriptPath = "\(scriptsFolder)/\(scriptName).js"
        NSWorkspace.shared.open(URL(fileURLWithPath: scriptPath))
    }
    
    /// Obtiene los parámetros de un script
    func getScriptParameters(for scriptName: String) -> [String: Any] {
        return interpreter.getScriptParameters(for: scriptName)
    }
    
    /// Actualiza un parámetro en un script
    func updateScriptParameter(script: String, parameter: String, value: Any) -> Bool {
        return interpreter.updateScriptParameter(script: script, parameter: parameter, value: value)
    }
    
    /// Obtiene la lista de scripts disponibles
    func getAvailableScripts() -> [String] {
        return availableScripts
    }
    
    /// Detiene el timer de recarga automática
    func stopAutoReload() {
        autoReloadTimer?.invalidate()
        autoReloadTimer = nil
    }
    
    deinit {
        stopAutoReload()
    }
}
