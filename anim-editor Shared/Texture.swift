import SpriteKit

class Texture {
    static func textureFromLocalPath(_ path: String) -> SKTexture? {
        #if os(macOS)
        let nsImage = NSImage(contentsOfFile: path)
        
        guard let image = nsImage else {
            print("Failed to load image from path: \(path)")
            return nil
        }
        
        guard let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!) else {
            print("Failed to create NSBitmapImageRep from NSImage")
            return nil
        }
        
        let cgImage = imageRep.cgImage
        let texture = SKTexture(cgImage: cgImage!)
        return texture
        
        #elseif os(iOS) || os(tvOS)
        let uiImage = UIImage(contentsOfFile: path)
        
        guard let image = uiImage else {
            print("Failed to load image from path: \(path)")
            return nil
        }
        
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage from UIImage")
            return nil
        }
        
        let texture = SKTexture(cgImage: cgImage)
        return texture
        #endif
    }
}
