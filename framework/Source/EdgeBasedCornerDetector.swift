//
//  EdgeBasedCornerDetector.swift
//  GPUImage
//
//  Created by PavanK on 7/21/20.
//  Copyright © 2020 Red Queen Coder, LLC. All rights reserved.
//

import Foundation
import Metal
import CoreGraphics
import UIKit

public class EdgeBasedCornerDetector: OperationGroup {

    let sobelEdgeDetectionFilter = SobelEdgeDetection()
    let nonMaximumSuppression = TextureSamplingOperation(fragmentFunctionName: "nonMaxSuppression")
    public var threshold:Float = 0.2 { didSet { nonMaximumSuppression.uniformSettings["threshold"] = threshold } }
    public var edgeStrength:Float = 1.0 { didSet { sobelEdgeDetectionFilter.uniformSettings["edgeStrength"] = edgeStrength } }
    public var cornersDetectedCallback:(([Position]) -> ())?
    let mono = LuminanceThreshold()

    public override init() {
        super.init()
        ({threshold = 0.175})()
        ({edgeStrength = 1.0})()
        

        outputImageRelay.newImageCallback = {texture in
            let img = texture.cgImage()
            if let cornersDetectedCallback = self.cornersDetectedCallback {
                cornersDetectedCallback(extractEdgeBasedCornersFromImage(img!))
            }
        }
        
        self.configureGroup {input, output in
            input --> self.sobelEdgeDetectionFilter --> self.mono --> output
        }
    }
    
    
}

func extractEdgeBasedCornersFromImage(_ cgImg: CGImage) -> [Position] {
    let data = cgImg.dataProvider?.data
    let bytes = CFDataGetBytePtr(data)
    var corners = [Position]()
    for y in 0 ..< cgImg.height {
        for x in 0 ..< cgImg.width {
            let offset = (y * cgImg.bytesPerRow) + (x * cgImg.bitsPerPixel/8)
            let components = (r: bytes![offset], g: bytes![offset + 1], b: bytes![offset + 2])
            if (components.r > 0 && components.g > 0 && components.b > 0) {
                corners.append(Position(Float(x)/Float(cgImg.width),Float(y)/Float(cgImg.height)))
            }
        }
    }
    return corners
}




func extractEdgeBasedCornersFromImage(_ texture: Texture) -> [Position] {
    
//    let startTime = CFAbsoluteTimeGetCurrent()
    let imageByteSize = Int(texture.texture.height * texture.texture.width * 4)
    let rawImagePixels = UnsafeMutablePointer<UInt8>.allocate(capacity:imageByteSize)
    
    let region = MTLRegionMake2D(0, 0, texture.texture.width, texture.texture.height)
    texture.texture.getBytes(rawImagePixels, bytesPerRow: texture.texture.width * 4, from: region, mipmapLevel: 0)
    let imageWidth = Int(texture.texture.width * 4)
    var corners = [Position]()

    var currentByte = 0
    while (currentByte < imageByteSize) {
        let colorByte = rawImagePixels[currentByte]
        if (colorByte > 0) {
            let xCoordinate = currentByte % imageWidth
            let yCoordinate = currentByte / imageWidth

            corners.append(Position(((Float(xCoordinate) / 4.0) / Float(texture.texture.width)), Float(yCoordinate) / Float(texture.texture.height)))
        }
        currentByte += 4
    }
    
    
    
    let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
    let bitsPerComponent = 8
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: rawImagePixels, width: texture.texture.width,
                            height: texture.texture.height,
                            bitsPerComponent: bitsPerComponent,
                            bytesPerRow: texture.texture.width * 4,
                            space: colorSpace,
                            bitmapInfo: bitmapInfo.rawValue)

    if let dstImage = context?.makeImage() {
        let img = UIImage(cgImage: dstImage)
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if let filePath = paths.first?.appendingPathComponent("MyImageName.png") {
            do {
               try img.pngData()?.write(to: filePath, options: .atomic)
            } catch {
               print(error)
            }
        }
    }

    rawImagePixels.deallocate()
//    print("Harris extraction frame time: \(CFAbsoluteTimeGetCurrent() - startTime) with total corners found = \(corners.count)")
    return corners
    
}



//func extractLinesFromImage(framebuffer: Framebuffer) -> [Line] {
//    let frameSize = framebuffer.size
//    let pixCount = UInt32(frameSize.width * frameSize.height)
//    let chanCount: UInt32 = 4
//    let imageByteSize = Int(pixCount * chanCount) // since we're comparing to currentByte, might as well cast here
//    let rawImagePixels = UnsafeMutablePointer<UInt8>.alloc(Int(imageByteSize))
//    glReadPixels(0, 0, frameSize.width, frameSize.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), rawImagePixels)
//    // since we only set one position with each iteration of the loop, we'll have ot set positions then combine into lines
//    //    linesArray = calloc(1024 * 2, sizeof(GLfloat)); - lines is 2048 floats - which is 1024 positions or 528 lines
//    var lines = Array<Line>()
//
//    let imageWidthInt = Int(framebuffer.size.width * 4)
////    let startTime = CFAbsoluteTimeGetCurrent()
//    var currentByte:Int = 0
////    var cornerStorageIndex: UInt32 = 0
//    var lineStrengthCounter: UInt64 = 0
//    while (currentByte < imageByteSize) {
//        let colorByte = rawImagePixels[currentByte]
//        if (colorByte > 0) {
//            let xCoordinate = currentByte % imageWidthInt
//            let yCoordinate = currentByte / imageWidthInt
//            lineStrengthCounter += UInt64(colorByte)
//            let normalizedXCoordinate = -1.0 + 2.0 * (Float)(xCoordinate / 4) / Float(frameSize.width)
//            let normalizedYCoordinate = -1.0 + 2.0 * (Float)(yCoordinate) / Float(frameSize.height)
////            print("(\(xCoordinate), \(yCoordinate)), [\(rawImagePixels[currentByte]), \(rawImagePixels[currentByte+1]), \(rawImagePixels[currentByte+2]), \(rawImagePixels[currentByte+3]) ] ")
//            let nextLine =
//                ( normalizedXCoordinate < 0.0
//                ? ( normalizedXCoordinate > -0.05
//                    // T space
//                    // m = -1 - d/u
//                    // b = d * v/u
//                    ? Line.infinite(slope:100000.0, intercept: normalizedYCoordinate)
//                    : Line.infinite(slope: -1.0 - 1.0 / normalizedXCoordinate, intercept: 1.0 * normalizedYCoordinate / normalizedXCoordinate)
//                )
//                : ( normalizedXCoordinate < 0.05
//                    // S space
//                    // m = 1 - d/u
//                    // b = d * v/u
//                    ? Line.infinite(slope: 100000.0, intercept: normalizedYCoordinate)
//                    : Line.infinite(slope: 1.0 - 1.0 / normalizedXCoordinate,intercept: 1.0 * normalizedYCoordinate / normalizedXCoordinate)
//                    )
//                )
//            lines.append(nextLine)
//        }
//        currentByte += 4
//    }
//    return lines
//}
