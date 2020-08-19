import Foundation

#if os(iOS)
import UIKit
#endif

public struct Position {
    public let x:Float
    public let y:Float
    public let z:Float?
    
    public init (_ x:Float, _ y:Float, _ z:Float? = nil) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public init(point:CGPoint) {
        self.x = Float(point.x)
        self.y = Float(point.y)
        self.z = nil
    }

    public static let center = Position(0.5, 0.5)
    public static let zero = Position(0.0, 0.0)
}


public struct Position2D {
    public let x:Float
    public let y:Float
    
    public init (_ x:Float, _ y:Float) {
        self.x = x
        self.y = y
    }
    
    public static let center = Position(0.5, 0.5)
    public static let zero = Position(0.0, 0.0)
}

public enum Line {
    case Infinite(slope:Float, intercept:Float)
    case Segment(p1:Position, p2:Position)

//    func toGLEndpoints() -> [GLfloat] {
//        switch self {
//        case .Infinite(let slope, let intercept):
//            if (slope > 9000.0) {// Vertical line
//                return [intercept, -1.0, intercept, 1.0]
//            } else {
//                return [-1.0, GLfloat(slope * -1.0 + intercept), 1.0, GLfloat(slope * 1.0 + intercept)]
//            }
//        case .Segment(let p1, let p2):
//            return [p1.x, p1.y, p2.x, p2.y].map {GLfloat($0)}
//        }
//    }
}
