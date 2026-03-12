import AVFoundation
import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformViewController = UIViewController
typealias PlatformView = UIView
#elseif canImport(AppKit)
import AppKit
typealias PlatformViewController = NSViewController
typealias PlatformView = NSView
#endif

@available(iOS 13, macOS 10.15, *)
private final class CameraViewController: PlatformViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private let cameraPosition: AVCaptureDevice.Position
    private var isSessionConfigured = false
    
    init(_ cameraPosition: AVCaptureDevice.Position) {
        self.cameraPosition = cameraPosition
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let rootView = PlatformView()
#if canImport(AppKit)
        rootView.wantsLayer = true
#endif
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermissionAndStartSession()
    }
    
#if canImport(UIKit)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreviewLayerFrame()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updatePreviewLayerOrientation()
        })
    }
#elseif canImport(AppKit)
    override func viewDidLayout() {
        super.viewDidLayout()
        updatePreviewLayerFrame()
    }
#endif
    
    private func checkPermissionAndStartSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                
                Task { @MainActor [weak self] in
                    self?.startSession()
                }
            }
            
        default:
            break
        }
    }
    
    private func startSession() {
        guard !isSessionConfigured else { return }
        
        setupCaptureSession()
        isSessionConfigured = true
        
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    private func setupCaptureSession() {
        guard
            let videoDevice = discoverVideoDevice(),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
        else {
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.addInput(videoDeviceInput)
        setupVideoOutput()
        captureSession.commitConfiguration()
        setupPreviewLayer()
    }
    
    private func discoverVideoDevice() -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: cameraPosition
        )
        
        return discoverySession.devices.first ?? AVCaptureDevice.default(for: .video)
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updatePreviewLayerOrientation()
#if canImport(UIKit)
            self.view.layer.addSublayer(self.previewLayer)
#elseif canImport(AppKit)
            self.view.layer?.addSublayer(self.previewLayer)
#endif
        }
    }
    
    private func setupVideoOutput() {
        guard captureSession.canAddOutput(videoOutput) else {
            return
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
#if canImport(UIKit)
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
#endif
    }
    
    private func updatePreviewLayerFrame() {
        previewLayer.frame = view.bounds
    }
    
    private func updatePreviewLayerOrientation() {
        updatePreviewLayerFrame()
        
#if canImport(UIKit)
        guard
            let connection = previewLayer.connection,
            connection.isVideoOrientationSupported
        else {
            return
        }
        
        switch view.window?.windowScene?.interfaceOrientation {
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
            
        case .landscapeLeft:
            connection.videoOrientation = .landscapeLeft
            
        case .landscapeRight:
            connection.videoOrientation = .landscapeRight
            
        default:
            connection.videoOrientation = .portrait
        }
#endif
    }
}

#if canImport(UIKit)
@available(iOS 13, macOS 10.15, *)
public struct CameraCapture: UIViewControllerRepresentable {
    private let cameraPosition: AVCaptureDevice.Position
    
    public init(_ cameraPosition: AVCaptureDevice.Position = .unspecified) {
        self.cameraPosition = cameraPosition
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        CameraViewController(cameraPosition)
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#elseif canImport(AppKit)
@available(iOS 13, macOS 10.15, *)
public struct CameraCapture: NSViewControllerRepresentable {
    private let cameraPosition: AVCaptureDevice.Position
    
    public init(_ cameraPosition: AVCaptureDevice.Position = .unspecified) {
        self.cameraPosition = cameraPosition
    }
    
    public func makeNSViewController(context: Context) -> NSViewController {
        CameraViewController(cameraPosition)
    }
    
    public func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
#endif
