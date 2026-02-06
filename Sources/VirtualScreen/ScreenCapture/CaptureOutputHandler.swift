import ScreenCaptureKit
import CoreVideo

protocol CaptureOutputReceiver: AnyObject {
    func didCaptureFrame(_ surface: IOSurfaceRef)
}

final class CaptureOutputHandler: NSObject, SCStreamOutput {
    weak var receiver: CaptureOutputReceiver?

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        let surface = CVPixelBufferGetIOSurface(pixelBuffer)
        guard let surface = surface else { return }
        let ioSurface = unsafeBitCast(surface, to: IOSurfaceRef.self)
        receiver?.didCaptureFrame(ioSurface)
    }
}
