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
    
    func addSpriteToScript(scriptId: String, sprite: Sprite) {
            if scriptSprites[scriptId] == nil {
                scriptSprites[scriptId] = []
            }
            scriptSprites[scriptId]?.append(sprite)
        }
        
        func clearScriptSprites(scriptId: String, spriteManager: SpriteManager) {
            guard let sprites = scriptSprites[scriptId] else { return }
            
            for sprite in sprites {
                spriteManager.removeSprite(sprite)
            }
            
            scriptSprites[scriptId] = []
        }
    
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
    
    func setupAPIBridge() {
            guard let particleManager = particleManager, let scene = scene else { return }
            
            // Crear el bridge API
            let apiBridge = ParticleAPIBridge(interpreter: self, particleManager: particleManager, scene: scene)
            
            // Registrar el bridge en el contexto global
            context.setObject(apiBridge, forKeyedSubscript: "ParticleAPI" as NSString)
        }
    
    // MARK: - Registro de funciones de API
    
    // Registra las funciones que estarán disponibles para los scripts JS
    private func registerAPIFunctions() {
        // Objeto global para la API
        let api = JSValue(newObjectIn: context)
        
        // --- Funciones de utilidad ---
        
        // Función para obtener la hora actual
        let getCurrentTime: @convention(block) () -> Int = { [weak self] in
            guard let scene = self?.scene,
                  let gameScene = scene as? GameScene,
                  let audioPlayer = gameScene.audioPlayer else {
                return 0
            }
            return Int(audioPlayer.currentTime * 1000)
        }
        
        // Función para generar números aleatorios
        let random: @convention(block) (Double, Double) -> Double = { (min, max) in
            return Double.random(in: min...max)
        }
        
        // Función para generar números aleatorios enteros
        let randomInt: @convention(block) (Int, Int) -> Int = { (min, max) in
            return Int.random(in: min...max)
        }

        
        // --- Registro de funciones en la API ---
        
        // Utilidades
        
        
        
        
        // --- Funciones de manejo de sprites ---
        
        // Función para crear un sprite individual
        let createSprite: @convention(block) (String) -> JSValue = { [weak self] (texturePath) in
            print("creando sprite")
            guard let self = self,
                  let particleManager = self.particleManager,
                  let texture = particleManager.textureLoader.getTexture(named: texturePath) else {
                print("❌ ERROR: No se pudo crear sprite con textura: \(texturePath)")
                // Debemos manejar el caso donde self es nil
                if let ctx = self?.context {
                    return JSValue(nullIn: ctx)
                } else {
                    return JSValue()
                }
            }
            
            // Crear un nuevo sprite
            let sprite = Sprite(texture: texture)
            print("✅ Sprite creado con textura: \(texturePath)")
            
            // Añadir a la lista de sprites del script actual
            if let scriptId = self.currentScriptId {
                if self.scriptSprites[scriptId] == nil {
                    self.scriptSprites[scriptId] = []
                }
                self.scriptSprites[scriptId]?.append(sprite)
                print("➕ Sprite añadido a script: \(scriptId), total sprites: \(self.scriptSprites[scriptId]?.count ?? 0)")
            }
            
            // Crear un objeto JS para representar este sprite
            let spriteObj = JSValue(newObjectIn: self.context)
            
            // Registrar métodos para el sprite - MoveX
            let addMoveXTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                sprite.addMoveXTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
            }
            spriteObj?.setValue(addMoveXTween, forProperty: "addMoveXTween")
            
            // Registrar métodos para el sprite - MoveY
            let addMoveYTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                sprite.addMoveYTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
            }
            spriteObj?.setValue(addMoveYTween, forProperty: "addMoveYTween")
            
            // Registrar métodos para el sprite - MoveTween combinado
            let addMoveTween: @convention(block) (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startX, startY, endX, endY, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                sprite.addMoveTween(easing: easing, startTime: startTime, endTime: endTime,
                                  startValue: CGPoint(x: startX, y: startY),
                                  endValue: CGPoint(x: endX, y: endY))
            }
            spriteObj?.setValue(addMoveTween, forProperty: "addMoveTween")
            
            // Registrar métodos para el sprite - Scale
            let addScaleTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                sprite.addScaleTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
            }
            spriteObj?.setValue(addScaleTween, forProperty: "addScaleTween")
            
            // Registrar métodos para el sprite - ScaleVec
            let addScaleVecTween: @convention(block) (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startX, startY, endX, endY, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                sprite.addScaleVecTween(easing: easing, startTime: startTime, endTime: endTime,
                                     startValue: CGPoint(x: startX, y: startY),
                                     endValue: CGPoint(x: endX, y: endY))
            }
            spriteObj?.setValue(addScaleVecTween, forProperty: "addScaleVecTween")
            
            // Registrar métodos para el sprite - Rotate
            let addRotateTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                sprite.addRotateTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
            }
            spriteObj?.setValue(addRotateTween, forProperty: "addRotateTween")
            
            // Registrar métodos para el sprite - Fade
            let addFadeTween: @convention(block) (Int, Int, CGFloat, CGFloat, String) -> Void = { (startTime, endTime, startValue, endValue, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                sprite.addFadeTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startValue, endValue: endValue)
            }
            spriteObj?.setValue(addFadeTween, forProperty: "addFadeTween")
            
            // Registrar métodos para el sprite - Color
            let addColorTween: @convention(block) (Int, Int, [NSNumber], [NSNumber], String) -> Void = { (startTime, endTime, startRGB, endRGB, easingStr) in
                let easing = self.getEasingFromString(easingStr)
                
                // Validar arrays RGB
                guard startRGB.count >= 3, endRGB.count >= 3 else { return }
                
                let startColor = SKColor(
                    red: CGFloat(startRGB[0].doubleValue / 255.0),
                    green: CGFloat(startRGB[1].doubleValue / 255.0),
                    blue: CGFloat(startRGB[2].doubleValue / 255.0),
                    alpha: 1.0
                )
                
                let endColor = SKColor(
                    red: CGFloat(endRGB[0].doubleValue / 255.0),
                    green: CGFloat(endRGB[1].doubleValue / 255.0),
                    blue: CGFloat(endRGB[2].doubleValue / 255.0),
                    alpha: 1.0
                )
                
                sprite.addColorTween(easing: easing, startTime: startTime, endTime: endTime, startValue: startColor, endValue: endColor)
            }
            spriteObj?.setValue(addColorTween, forProperty: "addColorTween")
            
            // Método para loop
            let startLoop: @convention(block) (Int, Int) -> Void = { (startTime, loopCount) in
                sprite.startLoop(startTime: startTime, loopCount: loopCount)
            }
            spriteObj?.setValue(startLoop, forProperty: "startLoop")
            
            let endLoop: @convention(block) () -> Void = {
                sprite.endLoop()
            }
            spriteObj?.setValue(endLoop, forProperty: "endLoop")
            
            // Método para modo de mezcla (blend mode)
            let addBlendMode: @convention(block) (Int, Int) -> Void = { (startTime, endTime) in
                sprite.addBlendModeTween(startTime: startTime, endTime: endTime)
            }
            spriteObj?.setValue(addBlendMode, forProperty: "addBlendMode")
            
            // Método para establecer posición inicial
            let setPosition: @convention(block) (CGFloat, CGFloat) -> Void = { (x, y) in
                sprite.setInitialPosition(position: CGPoint(x: x, y: y))
            }
            spriteObj?.setValue(setPosition, forProperty: "setPosition")
            
            // Añadir el sprite al spriteManager
            particleManager.spriteManager.addSprite(sprite)
            print("🔄 Sprite añadido al SpriteManager, total: \(particleManager.spriteManager.sprites.count)")
            
            return spriteObj!
        }
        
        // Función para limpiar efectos (sprites) creados por el script actual
        let clearEffects: @convention(block) () -> Void = { [weak self] in
            guard let self = self,
                  let scriptId = self.currentScriptId,
                  let sprites = self.scriptSprites[scriptId],
                  let particleManager = self.particleManager else {
                return
            }
            
            // Eliminar todos los sprites del script actual
            for sprite in sprites {
                particleManager.spriteManager.removeSprite(sprite)
            }
            
            // Limpiar lista
            self.scriptSprites[scriptId] = []
        }
        
        // --- Registro de funciones en la API ---
        
        // Utilidades
        api?.setValue(getCurrentTime, forProperty: "getCurrentTime")
        api?.setValue(random, forProperty: "random")
        api?.setValue(randomInt, forProperty: "randomInt")
        
        // Manejo de sprites
        api?.setValue(createSprite, forProperty: "createSprite")
        print("✅ Función createSprite registrada en la API")
        api?.setValue(clearEffects, forProperty: "clearEffects")
        
        context.setObject(api, forKeyedSubscript: "ParticleAPI" as NSString)
        print("✅ ParticleAPI registrado en el contexto principal con claves: \(api?.objectForKeyedSubscript(nil).toArray() ?? [])")
    }
    
    // MARK: - Funciones auxiliares
    
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
    
    // MARK: - Carga y ejecución de scripts
    
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
                scriptContext.setObject(apiBridge, forKeyedSubscript: "ParticleAPI" as NSString)
                
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
    
    func clearScriptsSprites(_ scriptName: String) {
        guard let sprites = scriptSprites[scriptName],
              let particleManager = particleManager else {
            return
        }
        
        print("🧹 Limpiando \(sprites.count) sprites existentes del script \(scriptName)")
        
        for sprite in sprites {
            particleManager.spriteManager.removeSprite(sprite)
        }
        
        scriptSprites[scriptName] = []
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

    
    // Limpia los sprites creados por un script específico
    private func clearScriptSprites(_ scriptName: String) {
        guard let sprites = scriptSprites[scriptName],
              let particleManager = particleManager else {
            return
        }
        
        for sprite in sprites {
            particleManager.spriteManager.removeSprite(sprite)
        }
        
        scriptSprites[scriptName] = []
    }
    
    // MARK: - Gestión de parámetros
    
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
            
            return result.toDictionary() as? [String: Any] ?? [:]
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


extension JSInterpreter {
    func testScript(scriptContent: String) {
        guard let testContext = JSContext() else {
            print("❌ Error al crear contexto de prueba")
            return
        }

        // Configurar manejador de excepciones para el contexto de prueba
        testContext.exceptionHandler = { _, exception in
            if let exc = exception {
                print("⚠️ [Test Script Error]: \(exc.toString() ?? "Unknown error")")
            }
        }

        // Inyectar la ParticleAPI en el contexto de prueba
        testContext.globalObject.setObject(
            context.globalObject.objectForKeyedSubscript("ParticleAPI"),
            forKeyedSubscript: "ParticleAPI" as NSString
        )

        print("🧪 Ejecutando script de prueba:\n\(scriptContent)")
        let result = testContext.evaluateScript(scriptContent)
        print("✅ Resultado del script de prueba: \(result ?? JSValue(undefinedIn: testContext)!)")

        // Intentar ejecutar la función main si está definida
        if let mainFn = testContext.objectForKeyedSubscript("main"),
           mainFn.isObject,
           !mainFn.isUndefined && mainFn.hasProperty("call") {
            print("📞 Llamando a la función main() en el script de prueba")
            mainFn.call(withArguments: [])
            print("✅ Función main() del script de prueba ejecutada")
        } else {
            print("⚠️ Advertencia: Función main() no encontrada en el script de prueba")
        }
    }
}

