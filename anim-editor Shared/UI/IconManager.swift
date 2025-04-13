//
//  IconManager.swift
//  anim-editor
//
//  Created by José Puma on 13-04-25.
//

import SpriteKit

class IconManager {
    // Singleton para acceso global
    static let shared = IconManager()
    
    // Cache de texturas para mejor rendimiento
    private var textureCache: [String: [SKColor: SKTexture]] = [:]
    
    // Listado de todos los iconos disponibles
    private var availableIcons: [String] = []
    
    // Constructor privado para singleton
    private init() {
        // Cargar automáticamente la lista de iconos disponibles
        loadAvailableIcons()
    }
    
    // Método para descubrir todos los iconos disponibles
    private func loadAvailableIcons() {
        availableIcons.removeAll()
        
        // 1. Buscar en el catálogo de assets
        if let iconsInAssets = loadIconsFromAssets() {
            availableIcons.append(contentsOf: iconsInAssets)
        }
        
        // 2. Buscar en la carpeta de recursos
        if let iconsInBundle = loadIconsFromBundle() {
            // Filtrar duplicados
            let newIcons = iconsInBundle.filter { !availableIcons.contains($0) }
            availableIcons.append(contentsOf: newIcons)
        }
        
        print("IconManager: Se encontraron \(availableIcons.count) iconos disponibles")
    }
    
    // Cargar iconos del catálogo de assets
    private func loadIconsFromAssets() -> [String]? {
        // Esta parte es más compleja porque no hay API directa para listar assets
        // Podríamos mantener un archivo de configuración o hacer que cada icono
        // tenga un prefijo común para identificarlos
        return nil
    }
    
    // Cargar iconos del bundle
    private func loadIconsFromBundle() -> [String]? {
        var iconNames: [String] = []
        
        // Buscar en la carpeta Icons
        if let resourcePath = Bundle.main.resourcePath {
            let iconsPath = resourcePath + "/Icons"
            
            do {
                let fileManager = FileManager.default
                // Verificar si la carpeta existe
                if fileManager.fileExists(atPath: iconsPath) {
                    let fileURLs = try fileManager.contentsOfDirectory(atPath: iconsPath)
                    
                    // Filtrar solo archivos PNG
                    let pngFiles = fileURLs.filter { $0.lowercased().hasSuffix(".png") }
                    
                    // Extraer nombres sin extensión
                    for file in pngFiles {
                        if let range = file.range(of: ".png", options: [.caseInsensitive]) {
                            let iconName = String(file[..<range.lowerBound])
                            iconNames.append(iconName)
                        }
                    }
                }
                
                // También buscar en la raíz del bundle
                let rootFiles = try fileManager.contentsOfDirectory(atPath: resourcePath)
                let pngFiles = rootFiles.filter { $0.lowercased().hasSuffix(".png") }
                
                for file in pngFiles {
                    if let range = file.range(of: ".png", options: [.caseInsensitive]) {
                        let iconName = String(file[..<range.lowerBound])
                        iconNames.append(iconName)
                    }
                }
            } catch {
                print("Error al leer el directorio de iconos: \(error)")
            }
        }
        
        return iconNames.isEmpty ? nil : iconNames
    }
    
    // Método para obtener la lista de iconos disponibles
    func getAvailableIcons() -> [String] {
        // Si la lista está vacía, intentar cargarla
        if availableIcons.isEmpty {
            loadAvailableIcons()
        }
        return availableIcons
    }
    
    // Método para forzar la recarga de la lista de iconos
    func refreshIconList() {
        loadAvailableIcons()
    }
    
    // Método principal para cargar y tintar un icono
    func getIcon(named iconName: String, size: CGFloat, color: SKColor = .white) -> SKSpriteNode {
        // Buscar en cache primero
        if let colorCache = textureCache[iconName], let texture = colorCache[color] {
            let sprite = SKSpriteNode(texture: texture)
            
            // Ajustar tamaño
            let aspectRatio = texture.size().width / texture.size().height
            if aspectRatio > 1 {
                sprite.size = CGSize(width: size, height: size / aspectRatio)
            } else {
                sprite.size = CGSize(width: size * aspectRatio, height: size)
            }
            
            return sprite
        }
        
        // Cargar la imagen
        var image = NSImage(named: iconName)
        
        // Si no se encuentra en el catálogo de assets, intentar en otras ubicaciones
        if image == nil {
            if let path = Bundle.main.path(forResource: "Icons/\(iconName)", ofType: "png") {
                image = NSImage(contentsOfFile: path)
            } else if let path = Bundle.main.path(forResource: iconName, ofType: "png") {
                image = NSImage(contentsOfFile: path)
            }
        }
        
        // Si no se encuentra la imagen, retornar un placeholder
        guard let img = image else {
            print("No se pudo cargar la imagen: \(iconName)")
            let placeholder = SKSpriteNode(color: .red, size: CGSize(width: size, height: size))
            placeholder.alpha = 0.5
            return placeholder
        }
        
        // Tintar la imagen manteniendo alta calidad
        let tintedImage = tintImageHighQuality(img, with: color)
        
        // Crear textura
        let texture = SKTexture(image: tintedImage)
        
        // Almacenar en cache
        if textureCache[iconName] == nil {
            textureCache[iconName] = [:]
        }
        textureCache[iconName]?[color] = texture
        
        // Crear sprite
        let sprite = SKSpriteNode(texture: texture)
        
        // Ajustar tamaño manteniendo proporción
        let aspectRatio = img.size.width / img.size.height
        if aspectRatio > 1 {
            sprite.size = CGSize(width: size, height: size / aspectRatio)
        } else {
            sprite.size = CGSize(width: size * aspectRatio, height: size)
        }
        
        return sprite
    }
    
    // Método para pre-cargar todos los iconos disponibles
    func preloadAllIcons(colors: [SKColor] = [.white]) {
        DispatchQueue.global(qos: .background).async {
            let icons = self.getAvailableIcons()
            for iconName in icons {
                for color in colors {
                    _ = self.getIcon(named: iconName, size: 16, color: color)
                }
            }
            print("IconManager: Pre-cargados \(icons.count) iconos con \(colors.count) colores")
        }
    }
    
    // Método para pre-cargar iconos específicos
    func preloadIcons(named iconNames: [String], colors: [SKColor] = [.white]) {
        DispatchQueue.global(qos: .background).async {
            for iconName in iconNames {
                for color in colors {
                    _ = self.getIcon(named: iconName, size: 16, color: color)
                }
            }
        }
    }
    
    // Método para limpiar la cache si necesitas liberar memoria
    func clearCache() {
        textureCache.removeAll()
    }
    
    // Método para tintar imagen con alta calidad
    private func tintImageHighQuality(_ image: NSImage, with color: NSColor) -> NSImage {
        let size = image.size
        let bounds = CGRect(origin: .zero, size: size)
        
        // Crear una nueva imagen con la misma escala que la original
        let tintedImage = NSImage(size: size)
        
        tintedImage.lockFocus()
        
        // Dibujar la imagen original como máscara
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let context = NSGraphicsContext.current?.cgContext
            
            // Asegurarse de limpiar el contexto
            context?.clear(bounds)
            
            // Configurar el color deseado
            color.set()
            
            // Configurar para usar la imagen como máscara (preservando alfa)
            context?.clip(to: bounds, mask: cgImage)
            
            // Rellenar la máscara con el color configurado
            context?.fill(bounds)
        }
        
        tintedImage.unlockFocus()
        
        return tintedImage
    }
}
