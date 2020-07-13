public class WhiteBalance: BasicOperation {
    public var temperature:Float = 5000.0 { didSet { uniformSettings["temperature"] = temperature < 5000.0 ? 0.0004 * (temperature - 5000.0) : 0.00006 * (temperature - 5000.0) } }
    public var tint:Float = 0.0 { didSet { uniformSettings["tint"] = tint / 100.0 } }
    
    public init() {
        super.init(fragmentFunctionName:"whiteBalanceFragmentShader", numberOfInputs:1)
        
        ({temperature = 5000.0})()
        ({tint = 0.0})()
        
        uniformSettings["RGBtoYIQ"] = Matrix3x3(rowMajorValues: [0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.212, -0.523, 0.311])
        uniformSettings["YIQtoRGB"] = Matrix3x3(rowMajorValues: [1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.105, 1.702])
    }
}
