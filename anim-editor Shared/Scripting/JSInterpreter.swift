//
//  JSInterpreter.swift
//  anim-editor
//
//  Created by José Puma on 17-04-25.
//

import Foundation
import JavaScriptCore
import SpriteKit

class JSInterpreter {
    // El contexto JS principal
    private let context: JSContext
    
    // Referencia al gestor de partículas
    private weak var particleManager: ParticleManager?
    
    // Referencia a la escena
    private weak var scene: SKScene?
    
    // Caché de scripts cargados (nombre -> contexto JS)
    private var scriptCache: [String: JSContext] = [:]
    
    // Sprites creados por scripts (para seguimiento y limpieza)
    private var scriptSprites: [String: [Sprite]] = [:]
    
    // ID del script actual que se está ejecutando
    internal var currentScriptId: String?
    
    private var scriptScenes: [String: ScriptScene] = [:]
    
    
    init(particleManager: ParticleManager, scene: SKScene) {
           self.particleManager = particleManager
           self.scene = scene
           
           // Inicializar el contexto JavaScript
           self.context = JSContext()!
           
           // Configurar el manejador de excepciones
           self.context.exceptionHandler = { context, exception in
               if let exc = exception {
                   print("JS Error: \(exc.toString() ?? "Unknown error")")
               }
           }
           
           setupConsoleObject()
       }
    
    func registerScriptScene(_ scriptName: String, scene: ScriptScene) {
       scriptScenes[scriptName] = scene
   }
    
    func addSpriteToScript(scriptId: String, sprite: Sprite) {
            if let scriptScene = scriptScenes[scriptId] {
                scriptScene.addSprite(sprite)
            }
        }
        
    func clearScriptsSprites(scriptId: String) {
        if let scriptScene = scriptScenes[scriptId] {
            scriptScene.clearAllSprites()
        }
    }
    
    // Convierte un string de easing a la enumeración Easing
    func getEasingFromString(_ string: String) -> Easing {
        switch string.lowercased() {
        case "linear": return .linear
        case "easein", "easing_in": return .easingIn
        case "easeout", "easing_out": return .easingOut
        case "easeinout", "easing_inout": return .quadInout
        case "quadin": return .quadIn
        case "quadout": return .quadOut
        case "quadinout": return .quadInout
        case "cubicin": return .cubicIn 
        case "cubicout": return .cubicOut
        case "cubicinout": return .cubicInOut
        case "sinein": return .sineIn
        case "sineout": return .sineOut
        case "sineinout": return .sineInOut
        case "expoin": return .expoIn
        case "expoout": return .expoOut
        case "expoinout": return .expoInOut
        case "circin": return .circIn
        case "circout": return .circOut
        case "circinout": return .circInOut
        case "elasticin": return .elasticIn
        case "elasticout": return .elasticOut
        case "elasticinout": return .elasticInOut
        case "backin": return .backIn
        case "backout": return .backOut
        case "backinout": return .backInOut
        case "bouncein": return .bounceIn
        case "bounceout": return .bounceOut
        case "bounceinout": return .bounceInOut
        default: return .linear
        }
    }
    
    func loadScript(from filePath: String) -> Bool {
            do {
                let scriptContent = try String(contentsOfFile: filePath, encoding: .utf8)
                let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
                
                // Crear un nuevo contexto
                guard let scriptContext = JSContext() else {
                    print("Error: No se pudo crear el contexto para el script \(fileName)")
                    return false
                }
                
                // Configurar console
                setupConsoleForContext(scriptContext, scriptName: fileName)
                
                // Crear y configurar el bridge para este contexto
                guard let particleManager = particleManager, let scene = scene else {
                    print("Error: particleManager o scene son nil")
                    return false
                }
                
                let apiBridge = ParticleAPIBridge(interpreter: self, particleManager: particleManager, scene: scene)
                scriptContext.setObject(apiBridge, forKeyedSubscript: "Sprite" as NSString)
                
                // Verificar
                print("✅ API Bridge configurado para script \(fileName)")
                
                // Evaluar el script
                scriptContext.evaluateScript(scriptContent)
                
                // Guardar en caché
                scriptCache[fileName] = scriptContext
                scriptSprites[fileName] = []
                
                // Intentar ejecutar init
                if let initFn = scriptContext.objectForKeyedSubscript("init"),
                   initFn.isObject,
                   !initFn.isUndefined {
                    initFn.call(withArguments: [])
                }
                
                return true
            } catch {
                print("Error cargando script \(filePath): \(error)")
                return false
            }
        }
        
    private func setupConsoleForContext(_ context: JSContext, scriptName: String) {
           let consoleObject = JSValue(newObjectIn: context)
           
           let logFunction: @convention(block) (String) -> Void = { message in
               print("📜 [JS Log - \(scriptName)] \(message)")
           }
           consoleObject?.setValue(logFunction, forProperty: "log")
           
           let errorFunction: @convention(block) (String) -> Void = { message in
               print("❌ [JS Error - \(scriptName)] \(message)")
           }
           consoleObject?.setValue(errorFunction, forProperty: "error")
           
           let warnFunction: @convention(block) (String) -> Void = { message in
               print("⚠️ [JS Warning - \(scriptName)] \(message)")
           }
           consoleObject?.setValue(warnFunction, forProperty: "warn")
           
           context.setObject(consoleObject, forKeyedSubscript: "console" as NSString)
           
           // Configurar manejador de excepciones
           context.exceptionHandler = { context, exception in
               if let exc = exception {
                   print("Error en script \(scriptName): \(exc.toString() ?? "Unknown error")")
               }
           }
       }
    
    // Busca y carga todos los scripts JS de una carpeta
    func loadScripts(fromFolder folderPath: String) -> [String] {
        let fileManager = FileManager.default
        var loadedScripts: [String] = []
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: folderPath),
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            for fileURL in fileURLs {
                if fileURL.pathExtension.lowercased() == "js" {
                    let fileName = fileURL.deletingPathExtension().lastPathComponent
                    if loadScript(from: fileURL.path) {
                        loadedScripts.append(fileName)
                    }
                }
            }
            
            return loadedScripts
        } catch {
            print("Error cargando scripts de la carpeta \(folderPath): \(error)")
            return []
        }
    }
    
    func clearScriptsSprites(_ scriptId: String) {
        if let scriptScene = scriptScenes[scriptId] {
            print("🧹 Limpiando escena para script: \(scriptId)")
            scriptScene.clearAllSprites()
        } else {
            print("⚠️ No se encontró escena para el script: \(scriptId)")
        }
    }
    
    // Ejecuta un script específico por nombre
    func executeScript(named scriptName: String) -> Bool {
        guard let scriptContext = scriptCache[scriptName] else {
            print("❌ Error: Script \(scriptName) no está cargado")
            return false
        }

        // Limpiar los sprites existentes para este script antes de ejecutarlo de nuevo
        clearScriptsSprites(scriptName)
        
        currentScriptId = scriptName
        print("🚀 Ejecutando script: \(scriptName)")

        print("🔍 Buscando la función main() en \(scriptName)")
        let success = executeMainFunction(in: scriptContext)
        print("✅ Ejecución de main() en \(scriptName) completada: \(success)")

        currentScriptId = nil
        return success
    }
    
    func executeScriptAsync(named scriptName: String, completion: @escaping (Bool) -> Void) {
        // Ejecutar en una cola de fondo para no bloquear el hilo principal
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Limpiar los sprites existentes en el hilo principal
            DispatchQueue.main.sync {
                self.clearScriptsSprites(scriptName)
            }
            
            // Establecer el ID del script actual
            self.currentScriptId = scriptName
            
            // Obtener el contexto del script
            guard let scriptContext = self.scriptCache[scriptName] else {
                print("❌ Error: Script \(scriptName) no está cargado")
                self.currentScriptId = nil
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Ejecutar el script
            let success = self.executeMainFunction(in: scriptContext)
            
            // Limpiar script ID
            self.currentScriptId = nil
            
            // Llamar al completion en el hilo principal
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func loadScriptAsync(from filePath: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            do {
                let scriptContent = try String(contentsOfFile: filePath, encoding: .utf8)
                let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
                
                // Crear un nuevo contexto
                guard let scriptContext = JSContext() else {
                    print("Error: No se pudo crear el contexto para el script \(fileName)")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                // Configuraciones que requieren el hilo principal
                var apiBridge: ParticleAPIBridge?
                DispatchQueue.main.sync {
                    // Configurar console
                    self.setupConsoleForContext(scriptContext, scriptName: fileName)
                    
                    // Crear y configurar el bridge para este contexto
                    guard let particleManager = self.particleManager, let scene = self.scene else {
                        print("Error: particleManager o scene son nil")
                        completion(false)
                        return
                    }
                    
                    apiBridge = ParticleAPIBridge(interpreter: self, particleManager: particleManager, scene: scene)
                    scriptContext.setObject(apiBridge, forKeyedSubscript: "Sprite" as NSString)
                }
                
                // Evaluar el script
                scriptContext.evaluateScript(scriptContent)
                
                // Guardar en caché
                DispatchQueue.main.sync {
                    self.scriptCache[fileName] = scriptContext
                    self.scriptSprites[fileName] = []
                }
                
                // Ejecutar init en el hilo principal si es necesario
                let success: Bool = {
                    if let initFn = scriptContext.objectForKeyedSubscript("init"),
                       initFn.isObject,
                       !initFn.isUndefined {
                        initFn.call(withArguments: [])
                    }
                    return true
                }()
                
                DispatchQueue.main.async {
                    completion(success)
                }
                
            } catch {
                print("Error cargando script \(filePath): \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // Ejecuta la función main() de un contexto
    private func executeMainFunction(in scriptContext: JSContext) -> Bool {
        if let mainFn = scriptContext.objectForKeyedSubscript("main"), mainFn.isObject, !mainFn.isUndefined && mainFn.hasProperty("call") {
            print("📞 Llamando a la función main()")
            mainFn.call(withArguments: [])
            print("✅ Función main() ejecutada")
            return true
        } else {
            print("⚠️ Advertencia: Script no tiene función main() o no es una función")
            return false
        }
    }

    
    // Obtiene los parámetros definidos para un script
    func getScriptParameters(for scriptName: String) -> [String: Any] {
        guard let scriptContext = scriptCache[scriptName] else {
            print("Error: Script \(scriptName) no está cargado")
            return [:]
        }
        
        // Intentar obtener los parámetros del script
        if let paramsFn = scriptContext.objectForKeyedSubscript("getParameters"),
           paramsFn.isObject,
           !paramsFn.isUndefined && paramsFn.hasProperty("call"),
           let result = paramsFn.call(withArguments: []),
           result.isObject {
            
            let typeInfoScript = """
                    (function() {
                        var result = {};
                        var params = getParameters();
                        Object.keys(params).forEach(function(key) {
                            result[key] = {
                                value: params[key],
                                type: typeof params[key]
                            };
                        });
                        return result;
                    })();
                    """
                    
            let typeInfo = scriptContext.evaluateScript(typeInfoScript)
            
            if let typeInfoDict = typeInfo?.toDictionary() as? [String: [String: Any]] {
                        // Crear un diccionario con los valores corregidos
                        var correctedParams: [String: Any] = [:]
                        
                        for (key, info) in typeInfoDict {
                            let value = info["value"]
                            let originalType = info["type"] as? String
                            
                            // Caso 1: Detectar booleanos originales
                            if originalType == "boolean" {
                                if let numValue = value as? Int {
                                    // Convertir 1/0 a Bool
                                    correctedParams[key] = numValue == 1 ? true : false
                                    print("✅ Convertido parámetro \(key) de Int(\(numValue)) a Bool (era booleano en JS)")
                                } else {
                                    // Mantener el valor tal cual si ya es un Bool
                                    correctedParams[key] = value
                                }
                            }
                            // Caso 2: Todos los demás valores se mantienen igual
                            else {
                                correctedParams[key] = value
                            }
                        }
                        
                        return correctedParams
                    }
                    
                    // Fallback: si algo falla, devolver los parámetros sin procesar
                    if let result = paramsFn.call(withArguments: []),
                       result.isObject {
                        return result.toDictionary() as? [String: Any] ?? [:]
                    }
        }
        
        return [:]
    }
    
    // Actualiza un parámetro en un script
    func updateScriptParameter(script: String, parameter: String, value: Any) -> Bool {
        guard let scriptContext = scriptCache[script] else {
            print("Error: Script \(script) no está cargado")
            return false
        }
        
        // Buscar la función de actualización en el script
        if let updateFn = scriptContext.objectForKeyedSubscript("updateParameter"),
           updateFn.isObject,
           !updateFn.isUndefined && updateFn.hasProperty("call") {
            
            // Convertir el valor a un JSValue
            let jsValue = JSValue(object: value, in: scriptContext)
            
            // Establecer el script actual
            currentScriptId = script
            
            // Llamar a la función updateParameter
            updateFn.call(withArguments: [parameter, jsValue as Any])
            
            // Restablecer script actual
            currentScriptId = nil
            
            return true
        }
        
        return false
    }
    
    private func setupConsoleObject() {
        // Crear el objeto console
        let consoleObject = JSValue(newObjectIn: context)
        
        // Implementar console.log
        let logFunction: @convention(block) (String) -> Void = { message in
            print("📜 [JS Log] \(message)")
        }
        consoleObject?.setValue(logFunction, forProperty: "log")
        
        // Implementar console.error
        let errorFunction: @convention(block) (String) -> Void = { message in
            print("❌ [JS Error] \(message)")
        }
        consoleObject?.setValue(errorFunction, forProperty: "error")
        
        // Implementar console.warn
        let warnFunction: @convention(block) (String) -> Void = { message in
            print("⚠️ [JS Warning] \(message)")
        }
        consoleObject?.setValue(warnFunction, forProperty: "warn")
        
        // Añadir el objeto console al contexto global
        context.setObject(consoleObject, forKeyedSubscript: "console" as NSString)
    }
}
