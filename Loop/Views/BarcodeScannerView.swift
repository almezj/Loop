import SwiftUI
import AVFoundation
import UIKit


// TODO: Fix the scanner, camera does not open when the start button is pressed and I dont know why.
struct BarcodeScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @State private var showingCamera = false
    @State private var mockBarcode = ""
    
    var body: some View {
        VStack(spacing: 20) {
            switch viewModel.scanStatus {
            case .idle:
                Button(action: {
                    #if targetEnvironment(simulator)
                    // In simulator, show test mode
                    viewModel.scanStatus = .scanning
                    #else
                    checkCameraPermission()
                    #endif
                }) {
                    Text("Start Scanning")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
            case .scanning:
                #if targetEnvironment(simulator)
                // Simulator test mode
                VStack(spacing: 20) {
                    Text("Simulator Test Mode")
                        .font(.headline)
                    
                    // Mock camera view
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Text("Camera Preview")
                                .foregroundColor(.white)
                        )
                    
                    // Test barcode input
                    TextField("Enter test barcode", text: $mockBarcode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        if !mockBarcode.isEmpty {
                            viewModel.processScanResult(mockBarcode)
                            mockBarcode = ""
                        }
                    }) {
                        Text("Simulate Scan")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                #else
                CameraView { result in
                    viewModel.processScanResult(result)
                }
                #endif
                
            case .success:
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 60))
                    Text("Success!")
                        .font(.title)
                    if let result = viewModel.scanResult {
                        Text("Barcode: \(result)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Button(action: viewModel.resetScan) {
                        Text("Scan Again")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
            case .error:
                VStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 60))
                    Text("Error")
                        .font(.title)
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    Button(action: viewModel.resetScan) {
                        Text("Try Again")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Scan Barcode")
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            viewModel.scanStatus = .scanning
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        viewModel.scanStatus = .scanning
                    }
                }
            }
        case .denied, .restricted:
            viewModel.scanStatus = .error
            viewModel.errorMessage = "Camera access is required to scan barcodes. Please enable camera access in Settings."
        @unknown default:
            viewModel.scanStatus = .error
            viewModel.errorMessage = "Unknown camera authorization status"
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    let onScanResult: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return viewController
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let previewLayer = uiViewController.view.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiViewController.view.layer.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first,
               let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let stringValue = readableObject.stringValue {
                parent.onScanResult(stringValue)
            }
        }
    }
} 
