//
//  ParticleScriptManager.swift
//  anim-editor
//
//  Created by José Puma on 17-04-25.
//

import Foundation
import SpriteKit
import Darwin

/// Clase encargada de gestionar los scripts de efectos de partículas con ejecución automática
class ParticleScriptManager {
    
    private var configManager: ProjectConfigManager
    
    // Intérprete JavaScript
    private let interpreter: JSInterpreter
    private var scriptScenes: [String: ScriptScene] = [:]
    var scriptExecutionOrder: [String] = []
    
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
    
    private let scriptProcessingQueue = OperationQueue()
    private let mainThreadSemaphore = DispatchSemaphore(value: 1)
    
    var onScriptsChanged: (([String]) -> Void)?
    
    init(particleManager: ParticleManager, scene: SKScene, scriptsFolder: String) {
        self.particleManager = particleManager
        self.scene = scene
        self.scriptsFolder = scriptsFolder
        self.templatesFolder = scriptsFolder + "/templates"
        
        // Inicializar el gestor de configuración
        let projectPath = scriptsFolder.components(separatedBy: "/scripts")[0]
        let projectName = URL(fileURLWithPath: projectPath).lastPathComponent
        self.configManager = ProjectConfigManager(projectPath: projectPath, projectName: projectName)
        
        // Inicializar el intérprete
        self.interpreter = JSInterpreter(particleManager: particleManager, scene: scene)
        
        scriptProcessingQueue.name = "com.animeditor.scriptprocessing"
        scriptProcessingQueue.maxConcurrentOperationCount = 1
        
        ensureDirectoriesExist()
        loadAndExecuteAllScripts()
        setupAutoReloadTimer()
    }
    
    private func loadScriptOrder() {
        // Obtener scripts de la configuración
        let configScripts = configManager.getScripts()
        
        if !configScripts.isEmpty {
            // Usar el orden definido en la configuración
            scriptExecutionOrder = configScripts
                .sorted { $0.zIndex < $1.zIndex }
                .map { $0.name }
                .filter { availableScripts.contains($0) }
            
            // Añadir scripts nuevos al final
            let existingNames = Set(scriptExecutionOrder)
            let newScripts = availableScripts.filter { !existingNames.contains($0) }
            scriptExecutionOrder.append(contentsOf: newScripts)
        } else {
            // Primera vez: usar el orden actual
            scriptExecutionOrder = availableScripts
            
            // Guardar orden inicial en la configuración
            for script in availableScripts {
                configManager.addOrUpdateScript(name: script)
            }
        }
    }
    
    private func saveScriptOrder() {
        configManager.updateScriptOrder(newOrder: scriptExecutionOrder)
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
        
        // Cargar el orden guardado
        loadScriptOrder()
        
        // Registrar fechas de modificación
        updateModificationDates()
        
        // Crear escenas para cada script y ejecutarlos en orden
        for scriptName in scriptExecutionOrder where availableScripts.contains(scriptName) {
            createScriptSceneIfNeeded(scriptName)
            let _ = executeScript(named: scriptName)
        }
        
        // Después de cargar todos los scripts, hacer fade in a todas las escenas
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.fadeInAllScriptScenes()
        }
    
    }
    
    private func fadeInAllScriptScenes() {
        for (_, scene) in scriptScenes {
            scene.fadeIn(duration: 0.4)
        }
    }
    
    func getScriptScenes() -> [String: ScriptScene] {
        return scriptScenes
    }
    
    private func createScriptSceneIfNeeded(_ scriptName: String) {
        // Si la escena ya existe, no hacer nada
        if scriptScenes[scriptName] != nil {
            return
        }
        
        guard let scene = self.scene else { return }
        
        // Crear nueva escena para este script
        let scriptScene = ScriptScene(scriptName: scriptName)
        scriptScene.alpha = 0.0 // Iniciar invisible solo para nuevas escenas
        scriptScenes[scriptName] = scriptScene
        
        // Registrar la escena con el intérprete
        interpreter.registerScriptScene(scriptName, scene: scriptScene)
        
        // Añadir a la escena principal en el orden correcto
        scene.addChild(scriptScene)
        
        // Establecer la escala
        if let gameScene = scene as? GameScene {
            scriptScene.setContentScale(gameScene.spriteManager.getScale())
        }
    }
    
    func reorderScriptScenes() {
            guard let scene = self.scene else { return }
            
            // Reordenar las escenas según el orden definido
            for scriptName in scriptExecutionOrder {
                if let scriptScene = scriptScenes[scriptName] {
                    // Remover y volver a añadir para que quede al final (encima)
                    scriptScene.removeFromParent()
                    scene.addChild(scriptScene)
                }
            }
        }
    
    func moveScriptUp(_ scriptName: String) -> Bool {
         guard let index = scriptExecutionOrder.firstIndex(of: scriptName), index > 0 else {
             return false
         }
         
         scriptExecutionOrder.remove(at: index)
         scriptExecutionOrder.insert(scriptName, at: index - 1)
         saveScriptOrder()
         
         // Reordenar las escenas
         reorderScriptScenes()
         
         return true
     }

    func moveScriptDown(_ scriptName: String) -> Bool {
            guard let index = scriptExecutionOrder.firstIndex(of: scriptName),
                  index < scriptExecutionOrder.count - 1 else {
                return false
            }
            
            scriptExecutionOrder.remove(at: index)
            scriptExecutionOrder.insert(scriptName, at: index + 1)
            saveScriptOrder()
            
            // Reordenar las escenas
            reorderScriptScenes()
            
            return true
        }

    // Obtener la lista ordenada
    func getOrderedScripts() -> [String] {
        return scriptExecutionOrder
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
        autoReloadTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForScriptChanges()
        }
    }
    
    // En ParticleScriptManager.swift
    func reorderAndReexecuteScripts() {
        // 1. Detener cualquier timer en ejecución para evitar conflictos
        autoReloadTimer?.invalidate()
        
        // 2. Limpiar todos los sprites existentes de todos los scripts
        for scriptName in availableScripts {
            interpreter.clearScriptsSprites(scriptName)
        }
        
        // 3. Ejecutar los scripts en el nuevo orden definido
        for scriptName in scriptExecutionOrder where availableScripts.contains(scriptName) {
            let _ = executeScript(named: scriptName)
        }
        
        // 4. Reiniciar el timer
        setupAutoReloadTimer()
        
        print("✅ Scripts reordenados y re-ejecutados en nuevo orden")
    }
    
    func reorderAndReexecuteScriptsNonBlocking() {
        // Detener cualquier timer en ejecución para evitar conflictos
        autoReloadTimer?.invalidate()
        
        // Aplicar fade out a todas las escenas de scripts
        fadeOutScriptScenes {
            // Una vez que el fade out haya terminado, continuar con la ejecución
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Limpiar sprites en el hilo principal
                for scriptName in self.availableScripts {
                    self.interpreter.clearScriptsSprites(scriptName)
                }
                
                // Reordenar las escenas
                self.reorderScriptScenes()
                
                // Ejecutar los scripts uno por uno con pequeños retrasos entre ellos
                self.executeScriptsWithDelay()
            }
        }
    }
    
    private func fadeOutScriptScenes(completion: @escaping () -> Void) {
        let fadeOutDuration: TimeInterval = 0.2
        
        // Si no hay escenas, llamar directamente al completion
        guard !scriptScenes.isEmpty else {
            completion()
            return
        }
        
        // Contador para saber cuándo todas las escenas han terminado su animación
        var completedCount = 0
        let totalCount = scriptScenes.count
        
        // Aplicar fade out a cada escena
        for (_, scene) in scriptScenes {
            let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: fadeOutDuration)
            scene.run(fadeOut) {
                completedCount += 1
                if completedCount >= totalCount {
                    completion()
                }
            }
        }
    }

    private func finishScriptExecution() {
        // Reiniciar el timer
        setupAutoReloadTimer()
        
        // Aplicar fade in a todas las escenas de scripts
        fadeInScriptScenes()
        
        print("✅ Scripts reordenados y re-ejecutados en nuevo orden")
    }

    /// Aplica un efecto de fade in a todas las escenas de scripts
    private func fadeInScriptScenes() {
        let fadeInDuration: TimeInterval = 0.3
        
        for (_, scene) in scriptScenes {
            // Asegurarse de que la escena esté inicialmente invisible (alpha 0)
            scene.alpha = 0.0
            
            // Aplicar fade in
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: fadeInDuration)
            scene.run(fadeIn)
        }
    }

    // Modificar el executeScriptsSequentiallyWithDelay para que no aplique fade in/out durante la ejecución
    private func executeScriptsSequentiallyWithDelay(scripts: [String], index: Int) {
        guard index < scripts.count else {
            // Terminamos de ejecutar todos los scripts
            finishScriptExecution()
            return
        }
        
        // Ejecutar el script actual
        let currentScript = scripts[index]
        _ = executeScript(named: currentScript)
        
        // Programar la ejecución del siguiente script con un pequeño retraso
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            self?.executeScriptsSequentiallyWithDelay(scripts: scripts, index: index + 1)
        }
    }

    /// Ejecuta los scripts secuencialmente con pequeños retrasos para evitar bloqueos
    private func executeScriptsWithDelay() {
        let scriptsToExecute = scriptExecutionOrder.filter { availableScripts.contains($0) }
        guard !scriptsToExecute.isEmpty else {
            finishScriptExecution()
            return
        }
        
        // Ejecutar el primer script y programar los siguientes recursivamente
        executeScriptsSequentiallyWithDelay(scripts: scriptsToExecute, index: 0)
    }

    // Métodos para notificar el inicio/fin del procesamiento (implementar según necesites)
    private func notifyScriptProcessingStarted() {
        // Mostrar un indicador de "cargando" si lo deseas
        // Esto se ejecuta en el hilo principal y es seguro
    }

    private func notifyScriptProcessingCompleted() {
        // Ocultar el indicador de "cargando"
        // Esto se ejecuta en el hilo principal y es seguro
    }
    
    /// Revisa si hay cambios en los scripts y los recarga si es necesario
    private func checkForScriptChanges() {
        let fileManager = FileManager.default
        
        // Obtener la lista actual de scripts en el directorio
        let currentScriptsInFolder = getScriptFilesInFolder()
        
        // Detectar scripts nuevos (están en la carpeta pero no en nuestra lista)
        let newScripts = currentScriptsInFolder.filter { !availableScripts.contains($0) }
        
        // Detectar scripts eliminados (están en nuestra lista pero no en la carpeta)
        let removedScripts = availableScripts.filter { !currentScriptsInFolder.contains($0) }
        
        // Si hay scripts nuevos o eliminados, actualizar la lista
        if !newScripts.isEmpty || !removedScripts.isEmpty {
            // Procesar scripts nuevos
            for script in newScripts {
                let scriptPath = "\(scriptsFolder)/\(script).js"
                if interpreter.loadScript(from: scriptPath) {
                    print("✅ Nuevo script cargado: \(script)")
                    
                    // Crear escena para el script nuevo (con alpha=0 para fade in)
                    createScriptSceneIfNeeded(script)
                    
                    // Añadir a la configuración y listas
                    if !scriptExecutionOrder.contains(script) {
                        configManager.addOrUpdateScript(name: script)
                        scriptExecutionOrder.append(script)
                    }
                    
                    // Ejecutar automáticamente el nuevo script
                    let _ = executeScript(named: script)
                    
                    // Aplicar fade in a la escena
                    if let scriptScene = scriptScenes[script] {
                        scriptScene.fadeIn()
                    }
                    
                    // Registrar fecha de modificación
                    registerScriptModificationDate(script, scriptPath)
                }
            }
            
            // Procesar scripts eliminados
            for script in removedScripts {
                print("🗑️ Script eliminado: \(script)")
                
                // Aplicar fade out antes de eliminar
                if let scriptScene = scriptScenes[script] {
                    scriptScene.fadeOut { [weak self] in
                        guard let self = self else { return }
                        
                        // Eliminar escena después del fade out
                        scriptScene.removeFromParent()
                        self.scriptScenes.removeValue(forKey: script)
                        
                        // Eliminar del orden y configuración
                        if let index = self.scriptExecutionOrder.firstIndex(of: script) {
                            self.scriptExecutionOrder.remove(at: index)
                            self.configManager.removeScript(name: script)
                        }
                    }
                } else {
                    // Si no hay escena, simplemente eliminar referencias
                    if let index = scriptExecutionOrder.firstIndex(of: script) {
                        scriptExecutionOrder.remove(at: index)
                        configManager.removeScript(name: script)
                    }
                }
                
                lastModificationDates.removeValue(forKey: script)
            }
            
            // Actualizar lista de scripts disponibles
            availableScripts = currentScriptsInFolder
            
            saveScriptOrder()
            
            // Notificar cambios para actualizar la UI
            notifyScriptsChanged()
        }
        
        // Verificar scripts modificados
        for scriptName in availableScripts {
            let scriptPath = "\(scriptsFolder)/\(scriptName).js"
            
            do {
                let attributes = try fileManager.attributesOfItem(atPath: scriptPath)
                if let modDate = attributes[.modificationDate] as? Date,
                   let lastModDate = lastModificationDates[scriptName],
                   modDate > lastModDate {
                    
                    print("📝 Script modificado: \(scriptName), recargando...")
                    
                    // Aplicar fade out a la escena antes de actualizarla
                    if let scriptScene = scriptScenes[scriptName] {
                        // Usar el método fadeOut con un completion handler
                        scriptScene.fadeOut { [weak self] in
                            guard let self = self else { return }
                            
                            // PRIMERO: Limpiar explícitamente la escena de este script
                            scriptScene.clearAllSprites()
                            
                            // DESPUÉS: Recargar el script
                            if self.interpreter.loadScript(from: scriptPath) {
                                // Ejecutar el script
                                let _ = self.executeScript(named: scriptName)
                                
                                // Actualizar fecha de modificación
                                self.lastModificationDates[scriptName] = modDate
                                
                                // Aplicar fade in después de un breve retraso
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    scriptScene.fadeIn()
                                }
                            }
                        }
                    } else {
                        // Si no existe la escena por alguna razón
                        if interpreter.loadScript(from: scriptPath) {
                            let _ = executeScript(named: scriptName)
                            lastModificationDates[scriptName] = modDate
                        }
                    }
                }
            } catch {
                print("Error verificando modificaciones de \(scriptPath): \(error)")
            }
        }
    }
    
    private func registerScriptModificationDate(_ scriptName: String, _ scriptPath: String) {
        do {
            let fileManager = FileManager.default
            let attributes = try fileManager.attributesOfItem(atPath: scriptPath)
            if let modDate = attributes[.modificationDate] as? Date {
                lastModificationDates[scriptName] = modDate
            }
        } catch {
            print("Error obteniendo atributos de \(scriptPath): \(error)")
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
        configManager.updateScriptSetting(scriptName: script, key: parameter, value: value)
        updateScriptFileWithNewParameter(scriptName: script, parameter: parameter, value: value)
        return interpreter.updateScriptParameter(script: script, parameter: parameter, value: value)
    }
    
    private func handleRemovedScript(_ scriptName: String) {
        interpreter.clearScriptsSprites(scriptName)
        configManager.removeScript(name: scriptName)
        
        // Remover del orden
        if let index = scriptExecutionOrder.firstIndex(of: scriptName) {
            scriptExecutionOrder.remove(at: index)
            saveScriptOrder()
        }
    }
    
    private func handleNewScript(_ scriptName: String) {
        configManager.addOrUpdateScript(name: scriptName)
        
        // Si no está en el orden, añadirlo
        if !scriptExecutionOrder.contains(scriptName) {
            scriptExecutionOrder.append(scriptName)
            saveScriptOrder()
        }
    }
    
    private func notifyScriptsChanged() {
        // Puedes implementar esto de varias maneras:
        
        // 1. Usando NotificationCenter (recomendado):
        NotificationCenter.default.post(name: NSNotification.Name("ScriptsListUpdated"), object: self)
        
        // 2. O mediante un callback si prefieres un enfoque más directo:
        if let callback = onScriptsChanged {
            callback(availableScripts)
        }
    }
    
    private func updateScriptFileWithNewParameter(scriptName: String, parameter: String, value: Any) {
        let scriptPath = "\(scriptsFolder)/\(scriptName).js"
        
        do {
            // Leer el contenido actual del script
            var scriptContent = try String(contentsOfFile: scriptPath, encoding: .utf8)
            
            // Convertir el valor a un string que sea válido en JavaScript
            let jsValue = convertValueToJSString(value)
            
            // Buscar el objeto params para analizar su estructura
            let paramsPattern = "var\\s+params\\s*=\\s*\\{([^\\}]*)\\}"
            
            if let regex = try? NSRegularExpression(pattern: paramsPattern, options: [.dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: scriptContent, options: [], range: NSRange(scriptContent.startIndex..<scriptContent.endIndex, in: scriptContent)),
               match.numberOfRanges > 1,
               let contentRange = Range(match.range(at: 1), in: scriptContent) {
                
                // Extraer el contenido interior del objeto params
                let paramsContent = String(scriptContent[contentRange])
                
                // Detectar si el parámetro ya existe usando múltiples patrones
                let paramPatterns = [
                    "\(parameter)\\s*:\\s*[^,}]+", // formato: parameter: value
                    "[\"\']\\s*\(parameter)\\s*[\"\']\\s*:\\s*[^,}]+" // formato: "parameter": value o 'parameter': value
                ]
                
                var foundAndReplaced = false
                var updatedContent = paramsContent
                
                for pattern in paramPatterns {
                    if let paramRegex = try? NSRegularExpression(pattern: pattern, options: []),
                       let paramMatch = paramRegex.firstMatch(in: paramsContent, options: [], range: NSRange(paramsContent.startIndex..<paramsContent.endIndex, in: paramsContent)),
                       let paramRange = Range(paramMatch.range, in: paramsContent) {
                        
                        // Encontrar la posición de los dos puntos
                        if let colonRange = paramsContent[paramRange].range(of: ":") {
                            let beforeColon = paramsContent[paramRange.lowerBound..<colonRange.upperBound]
                            
                            // Buscar hasta la coma o el final
                            var endOfValue = paramRange.upperBound
                            if let commaRange = paramsContent[colonRange.upperBound...].range(of: ",") {
                                endOfValue = commaRange.lowerBound
                            }
                            
                            // Construir el nuevo texto
                            let newParameterText = "\(beforeColon) \(jsValue)"
                            
                            // Reemplazar solo la parte del valor
                            let rangeToReplace = colonRange.upperBound..<endOfValue
                            updatedContent = updatedContent.replacingCharacters(in: rangeToReplace, with: " \(jsValue)")
                            
                            foundAndReplaced = true
                            break
                        }
                    }
                }
                
                if foundAndReplaced {
                    // Reemplazar el contenido del objeto params con el contenido actualizado
                    let fullParamsRange = Range(match.range, in: scriptContent)!
                    let newParamsText = "var params = {\(updatedContent)}"
                    scriptContent = scriptContent.replacingCharacters(in: fullParamsRange, with: newParamsText)
                    
                    // Escribir el contenido actualizado de vuelta al archivo
                    try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
                    print("✅ Script \(scriptName) actualizado con \(parameter) = \(jsValue)")
                } else {
                    // Si no se encontró el parámetro, añadirlo al final del objeto params
                    // Primero verificar si termina con coma
                    let endsWithComma = paramsContent.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix(",")
                    let separator = endsWithComma ? " " : ", "
                    
                    // Insertar el nuevo parámetro
                    let newParamsContent = endsWithComma ?
                        "\(paramsContent)\n  \(parameter): \(jsValue)" :
                        "\(paramsContent)\(separator)\n  \(parameter): \(jsValue)"
                    
                    // Reemplazar el objeto params completo
                    let fullParamsRange = Range(match.range, in: scriptContent)!
                    let newParamsText = "var params = {\(newParamsContent)}"
                    scriptContent = scriptContent.replacingCharacters(in: fullParamsRange, with: newParamsText)
                    
                    // Escribir el contenido actualizado de vuelta al archivo
                    try scriptContent.write(toFile: scriptPath, atomically: true, encoding: .utf8)
                    print("✅ Script \(scriptName) actualizado con parámetro añadido \(parameter) = \(jsValue)")
                }
            } else {
                print("⚠️ No se pudo encontrar o analizar el objeto params en \(scriptName)")
            }
        } catch {
            print("❌ Error actualizando el archivo de script: \(error)")
        }
    }

    // Función para convertir un valor de Swift a un string JavaScript válido
    private func convertValueToJSString(_ value: Any) -> String {
        switch value {
        case let number as Int:
            return "\(number)"
        case let number as Double:
            return "\(number)"
        case let number as Float:
            return "\(number)"
        case let boolean as Bool:
            return boolean ? "true" : "false"
        case let string as String:
            // Escapar comillas y caracteres especiales
            let escaped = string.replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        case let array as [Any]:
            let elements = array.map { convertValueToJSString($0) }.joined(separator: ", ")
            return "[\(elements)]"
        case let dictionary as [String: Any]:
            let entries = dictionary.map { key, value in
                let escapedKey = key.replacingOccurrences(of: "\"", with: "\\\"")
                return "\"\(escapedKey)\": \(convertValueToJSString(value))"
            }.joined(separator: ", ")
            return "{\(entries)}"
        default:
            return "null"
        }
    }
    
    /// Obtiene la lista de scripts disponibles
    func getAvailableScripts() -> [String] {
        return availableScripts
    }
    
    func textureForTime(time: Int, size: CGSize, completion: @escaping (SKTexture) -> Void) {
        DispatchQueue.main.async {
            let scale = CGFloat(854 / 256)
            
            let popupScene = SKScene(size: size)
            popupScene.backgroundColor = .black
            popupScene.scaleMode = .aspectFit
            popupScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            
            let sceneDictionaries = self.getScriptScenes()

            // Combinar todos los ScriptScenes en un solo array
            let allScenes = sceneDictionaries.compactMap { $0 } // eliminar nils si hay
                .compactMap { $0.value }

            // Ordenarlos según scriptExecutionOrder
            let orderedScenes = allScenes.sorted { first, second in
                guard let firstIndex = self.scriptExecutionOrder.firstIndex(of: first.scriptName),
                      let secondIndex = self.scriptExecutionOrder.firstIndex(of: second.scriptName) else {
                    return false
                }
                return firstIndex < secondIndex
            }

            // Ahora iterar sobre las escenas en orden
            for scriptScene in orderedScenes {
                let activeSpritesAtPosition = scriptScene.getSprites().filter { $0.isActive(at: time) }
                
                for sprite in activeSpritesAtPosition {
                    let spriteCopy = sprite.clone()
                    spriteCopy.update(currentTime: time, scale: scale)
                    popupScene.addChild(spriteCopy.node)
                }
            }
            
            let view = SKView()
            if let texture = view.texture(from: popupScene) {
                completion(texture)
            } else {
                // Textura de respaldo en caso de error
                let fallbackScene = SKScene(size: size)
                fallbackScene.backgroundColor = .darkGray
                
                let errorLabel = SKLabelNode(text: "Preview unavailable")
                errorLabel.fontColor = .white
                errorLabel.fontSize = 14
                errorLabel.position = CGPoint(x: size.width/2, y: size.height/2)
                fallbackScene.addChild(errorLabel)
                
                let fallbackTexture = view.texture(from: fallbackScene)!
                completion(fallbackTexture)
            }
        }
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
