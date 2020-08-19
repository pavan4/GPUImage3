#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif
import MetalKit

public enum PictureInputError: Error, CustomStringConvertible {
    case cgImageNilError
    case noSuchImageError(imageName:String)
    
    public var errorDescription:String {
        switch self {
        case .cgImageNilError:
            return "Unable to retrieve CGImage"
        case .noSuchImageError(let imageName):
            return "No such image named: \(imageName) in your application bundle"
        }
    }
    
    public var description:String {
        return "<\(type(of: self)): errorDescription = \(self.errorDescription)>"
    }
}

//public struct Offset {
//    public let x: Int
//    public let y: Int
//    
//    public init(x: Int, y: Int) {
//        self.x = x
//        self.y = y
//    }
//}
//
//public struct Dimensions {
//    let h: Int
//    let w: Int
//    
//    public init(w: Int, h: Int) {
//        self.w = w
//        self.h = h
//    }
//}

public class PictureInput: ImageSource {
    public let targets = TargetContainer()
    var internalTexture:Texture?
    public var textureUserInfo:[AnyHashable:Any]?
    var hasProcessedImage:Bool = false
    var internalImage:CGImage?
    
    let pictureInputProcessingQueue = DispatchQueue(label: "com.sunsetlakesoftware.GPUImage.pictureInputProcessingQueue")
//    var commandQueue: MTLCommandQueue!
//    var device: MTLDevice!
    
    public init(image:CGImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) {
        internalImage = image
//        device = MTLCreateSystemDefaultDevice()
//        commandQueue = device.makeCommandQueue()
    }
    
    #if canImport(UIKit)
    public convenience init(image:UIImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) throws {
        guard let cgImage = image.cgImage else { throw PictureInputError.cgImageNilError }
        self.init(image: cgImage, smoothlyScaleOutput: smoothlyScaleOutput, orientation: orientation)
    }
    
    public convenience init(imageName:String, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) throws {
        guard let image = UIImage(named:imageName) else { throw PictureInputError.noSuchImageError(imageName:imageName)}
        try self.init(image:image, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }
    #else
    public convenience init(image:NSImage, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) throws {
        guard let cgImage = image.cgImage(forProposedRect:nil, context:nil, hints:nil) else { throw PictureInputError.cgImageNilError }
        self.init(image:cgImage, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }
    
    public convenience init(imageName:String, smoothlyScaleOutput:Bool = false, orientation:ImageOrientation = .portrait) throws {
        let imageName = NSImage.Name(imageName)
        guard let image = NSImage(named:imageName) else { throw PictureInputError.noSuchImageError(imageName:imageName) }
        self.init(image:image.cgImage(forProposedRect:nil, context:nil, hints:nil)!, smoothlyScaleOutput:smoothlyScaleOutput, orientation:orientation)
    }
    #endif
    
    public init(texture:MTLTexture, rect:CGRect? = nil, orientation:ImageOrientation = .portrait){
        var newTexture: MTLTexture
        
//        device = MTLCreateSystemDefaultDevice()
//        commandQueue = sharedMetalRenderingDevice.device.makeCommandQueue()
        if let rect = rect {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.pixelFormat = texture.pixelFormat
            textureDescriptor.width = Int(rect.width)
            textureDescriptor.height = Int(rect.height)
            
            newTexture = sharedMetalRenderingDevice.device.makeTexture(descriptor: textureDescriptor)!
                
            let sourceRegion = MTLRegionMake2D(Int(rect.origin.x), Int(rect.origin.y), Int(rect.width), Int(rect.height))
            let destOrigin = MTLOrigin(x: 0, y: 0, z: 0)
            let firstSlice = 0
            let lastSlice = 0
            
            let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer()
            let blitEncoder = commandBuffer!.makeBlitCommandEncoder()

            for slice in firstSlice...lastSlice {
                blitEncoder!.copy(from: texture,
                                 sourceSlice: slice,
                                 sourceLevel: 0,
                                 sourceOrigin: sourceRegion.origin,
                                 sourceSize: sourceRegion.size,
                                 to: newTexture,
                                 destinationSlice: slice - firstSlice,
                                 destinationLevel: 0,
                                 destinationOrigin: destOrigin)
            }
            
            blitEncoder!.endEncoding()
            commandBuffer!.commit()
            commandBuffer!.waitUntilCompleted()
        }
        else {
            newTexture = texture
        }
        
//        let imageByteSize = Int(newTexture.height * newTexture.width * 4)
//        let rawImagePixels = UnsafeMutablePointer<UInt8>.allocate(capacity:imageByteSize)
//
//        let region = MTLRegionMake2D(0, 0, newTexture.width, newTexture.height)
//        newTexture.getBytes(rawImagePixels, bytesPerRow: newTexture.width * 4, from: region, mipmapLevel: 0)
//
//        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
//        let bitsPerComponent = 8
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let context = CGContext(data: rawImagePixels, width: newTexture.width,
//                                height: newTexture.height,
//                                bitsPerComponent: bitsPerComponent,
//                                bytesPerRow: newTexture.width * 4,
//                                space: colorSpace,
//                                bitmapInfo: bitmapInfo.rawValue)

//        if let dstImage = context?.makeImage() {
//            internalImage = dstImage
//            let img = UIImage(cgImage: dstImage, scale: 0.0, orientation: .up)
//            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//            if let filePath = paths.first?.appendingPathComponent("MyImageName.png") {
//                do {
//                   try img.pngData()?.write(to: filePath, options: .atomic)
//                } catch {
//                   print(error)
//                }
//            }
//        }

        self.internalTexture = Texture(orientation: orientation, texture: newTexture)
        self.internalTexture?.userInfo = self.textureUserInfo
    }
    
    public func processTexture() {
        self.updateTargetsWithTexture(self.internalTexture!)
        self.hasProcessedImage = true
    }
    
    public func processImage(synchronously:Bool = false) {
        if let texture = internalTexture {
            texture.userInfo = self.textureUserInfo
            if synchronously {
                autoreleasepool {
                    self.updateTargetsWithTexture(texture)
                }
                self.hasProcessedImage = true
            } else {
                self.pictureInputProcessingQueue.async {
                    autoreleasepool {
                        self.updateTargetsWithTexture(texture)
                    }
                    self.hasProcessedImage = true
                }
            }
        } else {
            let textureLoader = MTKTextureLoader(device: sharedMetalRenderingDevice.device)
            if synchronously {
                do {
                    let imageTexture = try textureLoader.newTexture(cgImage:internalImage!, options: [MTKTextureLoader.Option.SRGB : false])
                    internalImage = nil
                    self.internalTexture = Texture(orientation: .portrait, texture: imageTexture)
                    self.internalTexture?.userInfo = self.textureUserInfo
                    self.updateTargetsWithTexture(self.internalTexture!)
                    self.hasProcessedImage = true
                } catch {
                    Log.error("Error loading image texture: \(error)")
                    return
                }
            } else {
                textureLoader.newTexture(cgImage:internalImage!, options: [MTKTextureLoader.Option.SRGB : false], completionHandler: { (possibleTexture, error) in
                    guard (error == nil) else {
                        Log.error("Error loading image texture: \(error!)")
                        return
                    }
                    guard let texture = possibleTexture else {
                        Log.error("Nil texture received")
                        return
                    }
                    self.internalImage = nil
                    self.internalTexture = Texture(orientation: .portrait, texture: texture)
                    self.internalTexture?.userInfo = self.textureUserInfo
                    self.pictureInputProcessingQueue.async {
                        autoreleasepool {
                            self.updateTargetsWithTexture(self.internalTexture!)
                        }
                        self.hasProcessedImage = true
                    }
                })
            }
        }
    }
    
    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        if hasProcessedImage {
            target.newTextureAvailable(self.internalTexture!, fromSourceIndex:atIndex)
        }
    }
}
