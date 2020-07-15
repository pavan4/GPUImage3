import Foundation
import MetalKit

// These delegate calls may be called by any thread
public protocol RenderViewDelegate: class {
    func willDisplayTexture(renderView: RenderView, texture: Texture)
    func didDisplayTexture(renderView: RenderView, texture: Texture)
}

public class RenderView: MTKView, ImageConsumer {
    public weak var renderViewDelegate:RenderViewDelegate?
    
    public let sources = SourceContainer()
    public let maximumInputs: UInt = 1
    var currentTexture: Texture?
    var renderPipelineState:MTLRenderPipelineState!
    
    public override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: sharedMetalRenderingDevice.device)
        
        commonInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        framebufferOnly = false
        autoResizeDrawable = true
        
        self.device = sharedMetalRenderingDevice.device
        
        let (pipelineState, _, _) = generateRenderPipelineState(device:sharedMetalRenderingDevice, vertexFunctionName:"oneInputVertex", fragmentFunctionName:"passthroughFragment", operationName:"RenderView")
        self.renderPipelineState = pipelineState
        
        enableSetNeedsDisplay = false
        isPaused = true
    }
    
    public func newTextureAvailable(_ texture:Texture, fromSourceIndex:UInt) {
        self.drawableSize = CGSize(width: texture.texture.width, height: texture.texture.height)
        currentTexture = texture
        self.draw()
    }
    
    public override func draw(_ rect:CGRect) {
        // Necessary according to https://developer.apple.com/documentation/quartzcore/cametallayer
        // Without this we were getting a deadlock when setting drawableSize
        autoreleasepool {
            guard let commandBuffer = sharedMetalRenderingDevice.commandQueue.makeCommandBuffer() else {
                Log.warning("Could not make command buffer")
                return
            }
            
            guard let currentDrawable = self.currentDrawable else {
                Log.warning("Could not retrieve current drawable")
                return
            }
            
            guard let currentTexture = self.currentTexture else {
                Log.warning("Could not retrieve current texture")
                return
            }
            
            self.renderViewDelegate?.willDisplayTexture(renderView: self, texture: currentTexture)
            
            let outputTexture = Texture(orientation: .portrait, texture: currentDrawable.texture)
            commandBuffer.renderQuad(pipelineState: renderPipelineState, inputTextures: [0:currentTexture], outputTexture: outputTexture)
            
            commandBuffer.present(currentDrawable)
            commandBuffer.addCompletedHandler({ (commandBuffer) in
                self.renderViewDelegate?.didDisplayTexture(renderView: self, texture: currentTexture)
            })
            commandBuffer.commit()
        }
    }
}


