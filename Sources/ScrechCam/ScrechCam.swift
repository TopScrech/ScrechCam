import SwiftUI
import AVFoundation

@available(iOS 13, macOS 10.15, *)
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var permissionGranted = false
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var screenRect = UIScreen.main.bounds
    private var videoOutput = AVCaptureVideoDataOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkPermission()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else {
                return
            }
            
            setupCaptureSession()
            
            captureSession.startRunning()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updatePreviewLayerOrientation()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            
        case .notDetermined:
            requestPermission()
            
        default:
            permissionGranted = false
        }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            permissionGranted = granted
            sessionQueue.resume()
        }
    }
    
    func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else { return }
        
        captureSession.addInput(videoDeviceInput)
        setupPreviewLayer()
        setupVideoOutput()
    }
    
    func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = screenRect
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        
        DispatchQueue.main.async { [weak self] in
            self?.view.layer.addSublayer(self!.previewLayer)
        }
    }
    
    func setupVideoOutput() {
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
    }
    
    func updatePreviewLayerOrientation() {
        screenRect = UIScreen.main.bounds
        previewLayer.frame = screenRect
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
            
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeRight
            
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeLeft
            
        case .portrait:
            previewLayer.connection?.videoOrientation = .portrait
            
        default: break
        }
    }
}

@available(iOS 13, macOS 10.15, *)
public struct CameraCapture: UIViewControllerRepresentable {
    public init() {}
    
    public func makeUIViewController(context: Context) -> UIViewController {
        ViewController()
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

