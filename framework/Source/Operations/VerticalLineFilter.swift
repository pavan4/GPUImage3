//
//  File.swift
//  GPUImage_iOS
//
//  Created by PavanK on 7/27/20.
//  Copyright © 2020 Red Queen Coder, LLC. All rights reserved.
//

import CoreGraphics

public class VerticalLineFilter: OperationGroup {
    
    let nonMaximumSuppression = TextureSamplingOperation(fragmentFunctionName: "nonMaxSuppression")
    public var threshold:Float = 0.2 { didSet { nonMaximumSuppression.uniformSettings["threshold"] = threshold } }
    let vLineConv = Convolution3x3()
    public var getLinesCallback:((Int) -> ())?
    
    
    
    public override init() {
        super.init()
        
        ({threshold = 0.05})()
        vLineConv.convolutionKernel = Matrix3x3(rowMajorValues:[ -1,2,-1,-1,2,-1,-1,2,-1])
        
        outputImageRelay.newImageCallback = {texture in
            let img = texture.cgImage()
            if let getLinesCallback = self.getLinesCallback {
                getLinesCallback(lineEqns(img!))
            }
        }
        
        self.configureGroup { input, output in
            input --> self.vLineConv --> self.nonMaximumSuppression --> output
            
        }
        
    }
}

func lineEqns(_ cgImg: CGImage) -> Int {
    
    let d = hypotf(Float(cgImg.height), Float(cgImg.width))
    let dtheta = 180 / 180.0
    let drho = (2 * d) / 180.0
    
    let thetas =  Array(stride(from: Float(0), to: Float(180.0), by: Float(dtheta)))
    let rhos =  Array(stride(from: Float(-d), to: Float(d), by: Float(drho)))
    
    let cos_thetas = thetas.map { cos(deg2rad($0)) }
    let sin_thetas = thetas.map { sin(deg2rad($0)) }

    var accumulator = [[Int]](repeating: [Int](repeating: 0, count: rhos.count), count: rhos.count)
    let data = cgImg.dataProvider?.data
    let bytes = CFDataGetBytePtr(data)
    var ys = [Float]()
    var xs = [Float]()
    let t_count = 150
    var startTime = CFAbsoluteTimeGetCurrent()
    
    for y in 0..<cgImg.height {
        for x in 0..<cgImg.height {
            let offset = (y * cgImg.bytesPerRow) + (x * cgImg.bitsPerPixel/8)
            let components = (r: bytes![offset], g: bytes![offset + 1], b: bytes![offset + 2])
            if (components.r > 0 && components.g > 0 && components.b > 0) {
                let edge_point = [y - cgImg.height/2, x - cgImg.width/2]
                for theta_idx in 0..<thetas.count {
                    let rho = (Float(edge_point[1]) * cos_thetas[theta_idx]) + (Float(edge_point[0]) * sin_thetas[theta_idx])
                    let theta = thetas[theta_idx]
                    let rho_idx = rhos.indexOfMin(rho: rho) //.map { $0 - rho }
                    accumulator[rho_idx!][theta_idx] += 1
                    ys.append(rho)
                    xs.append(theta)
                }
               
            }
        }
    }
    print(" \(CFAbsoluteTimeGetCurrent() - startTime) ")
    startTime = CFAbsoluteTimeGetCurrent()
    for y in 0..<accumulator[0].count {
        for x in 0..<accumulator[0].count {
            if accumulator[y][x] > t_count {
                let rho = rhos[y]
                let theta = thetas[x]
                let a = cos(deg2rad(theta))
                let b = sin(deg2rad(theta))
                let x0 = (a * rho) + Float(cgImg.width/2)
                let y0 = (b * rho) + Float(cgImg.height/2)
                let x1 = Int(x0 * (-b))
                let y1 = Int(y0 * (a))
                let x2 = Int(x0 + 100 * (-b))
                let y2 = Int(y0 + 100 * (a))
                print("[ \(x1) ,\(y1) ], [ \(x2), \(y2) ]")
            }
        }
    }
    print(" \(CFAbsoluteTimeGetCurrent() - startTime) , ** ")
    return 1
}


func deg2rad(_ number: Float) -> Float {
    return number * .pi / 180
}

// https://stackoverflow.com/questions/43806967/finding-indices-of-max-value-in-swift-array
extension Array where Element: Comparable {
    func indexOfMin(rho: Float) -> Int? {
        var minValue : Float = (self.first as! Float - rho)
        var minIndex = 0

        for (index, value) in self.enumerated() {
            let val = (value as! Float - rho)
            if val < minValue {
                minValue = val
                minIndex = index
            }
        }
        return minIndex
    }
}
