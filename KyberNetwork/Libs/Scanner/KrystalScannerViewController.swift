//
//  KrystalScannerViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 08/07/2022.
//

import UIKit
import AVFoundation

class KrystalScannerViewController: UIViewController {
  @IBOutlet weak var previewView: UIView!
  @IBOutlet weak var holeCover: CameraHoleCover!
  @IBOutlet weak var segmentView: CustomSegmentView!
  @IBOutlet weak var titleLabel: UILabel!
  
  let captureSession = AVCaptureSession()
  lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
  let videoDataOutput = AVCaptureVideoDataOutput()
  
  // Support drawing
  let borderLayer = CAShapeLayer()
  let maskLayer = CAShapeLayer()
  var lastTouch: CGPoint = .zero
  let minHoleSize: CGFloat = 64
  let maxHoleWidth: CGFloat = UIScreen.main.bounds.width - 48
  var lastHoleFrame: CGRect = .zero
  var isDraggingEnabled = false
  
  var availableScanModes: [ScanMode] = [.qr, .ocr]
  
  var detector: TextDetector = BarCodeDetector()
  
  var scanMode: ScanMode = .qr {
    didSet {
      self.titleLabel.text = self.title(forMode: scanMode)
      switch scanMode {
      case .qr:
        isDraggingEnabled = false
        detector = BarCodeDetector()
      case .ocr:
        isDraggingEnabled = true
        detector = OcrDetector()
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupViews()
    self.setupSegmentView()
    self.setCameraInput()
    self.showCameraFeed()
    self.setCameraOutput()
    
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    holeCover.addGestureRecognizer(panGesture)
  }
  
  override func loadView() {
    super.loadView()
    
    self.view.backgroundColor = .white // Fix bug lagging when push, don't know why
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
    self.captureSession.startRunning()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.videoDataOutput.setSampleBufferDelegate(nil, queue: nil)
    self.captureSession.stopRunning()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    self.previewLayer.frame = self.previewView.bounds
  }
  
  @IBAction func closeWasTapped(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
  
  func setupViews() {
    self.titleLabel.text = self.title(forMode: self.scanMode)
  }
  
  func title(forMode scanMode: ScanMode) -> String {
    switch scanMode {
    case .qr:
      return Strings.scanQRCode
    case .ocr:
      return Strings.scanText
    }
  }
  
  func setupSegmentView() {
    segmentView.items = availableScanModes.map(\.title)
    segmentView.onSelectItem = { [weak self] index in
      guard let self = self else { return }
      let mode = self.availableScanModes[index]
      self.scanMode = mode
      
      let width = self.view.frame.width * 3 / 4
      switch mode {
      case .qr:
        self.holeCover.holeFrame = .init(x: self.view.frame.midX - width / 2,
                                         y: self.view.frame.midY - width / 2,
                                         width: width, height: width)
      case .ocr:
        let height = width / 2
        self.holeCover.holeFrame = .init(x: self.view.frame.midX - width / 2,
                                         y: self.view.frame.midY - height / 2,
                                         width: width, height: height)
      }
    }
  }
  
  private func setCameraInput() {
    guard let device = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
      mediaType: .video,
      position: .back).devices.first else {
      print("No back camera device found.")
      return
    }
    let cameraInput = try! AVCaptureDeviceInput(device: device)
    self.captureSession.addInput(cameraInput)
  }
  
  private func showCameraFeed() {
    self.previewLayer.videoGravity = .resizeAspectFill
    self.previewView.layer.addSublayer(self.previewLayer)
    self.previewLayer.frame = self.previewView.frame
  }
  
  private func setCameraOutput() {
    self.videoDataOutput.videoSettings = [
      (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
    ]
    
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
    self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
    self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
    self.captureSession.addOutput(self.videoDataOutput)
    
    guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
          connection.isVideoOrientationSupported else { return }
    
    connection.videoOrientation = .portrait
  }
  
}

extension KrystalScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    detector.detect(buffer: sampleBuffer) { [weak self] texts in
      // On result
      
    }
  }
}

extension KrystalScannerViewController {
  
  @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
    guard isDraggingEnabled else { return }
    switch recognizer.state {
    case .began:
      lastTouch = recognizer.location(in: self.view)
      lastHoleFrame = holeCover.holeFrame
    case .changed:
      let location = recognizer.location(in: self.view)
      
      let dx = location.x - lastTouch.x
      let dy = location.y - lastTouch.y
      let dxLastTouchToCenter = lastTouch.x - view.center.x
      let dyLastTouchToCenter = lastTouch.y - view.center.y
      
      var newWidth = lastHoleFrame.width
      var newHeight = lastHoleFrame.height
      
      if dx * dxLastTouchToCenter < 0 {
        if newWidth - abs(dx) * 2 >= minHoleSize && newWidth - abs(dx) * 2 <= maxHoleWidth {
          newWidth -= abs(dx) * 2
        } else {
          newWidth = holeCover.holeFrame.width
        }
      } else {
        if newWidth + abs(dx) * 2 >= minHoleSize && newWidth + abs(dx) * 2 <= maxHoleWidth {
          newWidth += abs(dx) * 2
        } else {
          newWidth = holeCover.holeFrame.width
        }
      }
      if dy * dyLastTouchToCenter < 0 {
        if newHeight - abs(dy) * 2 >= minHoleSize && newHeight - abs(dy) * 2 <= 500 {
          newHeight -= abs(dy) * 2
        } else {
          newHeight = holeCover.holeFrame.height
        }
      } else {
        if newHeight + abs(dy) * 2 >= minHoleSize && newHeight + abs(dy) * 2 <= 500 {
          newHeight += abs(dy) * 2
        } else {
          newHeight = holeCover.holeFrame.height
        }
      }

      let newFrame = CGRect(x: holeCover.frame.midX - newWidth / 2,
                            y: holeCover.frame.midY - newHeight / 2,
                            width: newWidth, height: newHeight)
      holeCover.holeFrame = newFrame
    default:
      return
    }
    
  }
  
}
