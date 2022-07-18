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
  @IBOutlet weak var resultLabel: UILabel!
  @IBOutlet weak var holeCover: CameraHoleCover!
  
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
  
  var availableScanModes: [ScanMode] = [.qr, .ocr]
  
  var detector: TextDetector = BarCodeDetector()
  
  var scanMode: ScanMode = .qr {
    didSet {
      switch scanMode {
      case .qr:
        detector = BarCodeDetector()
      case .ocr:
        detector = OcrDetector()
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setCameraInput()
    self.showCameraFeed()
    self.setCameraOutput()
    
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    holeCover.addGestureRecognizer(panGesture)
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
      DispatchQueue.main.async {
        self?.resultLabel.text = texts.joined(separator: " ")
      }
    }
  }
}

extension KrystalScannerViewController {
  
  @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
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

extension CGPoint {
  
  func distanceSquared(from: CGPoint) -> CGFloat {
      return (from.x - x) * (from.x - x) + (from.y - y) * (from.y - y)
  }

  func distance(from: CGPoint) -> CGFloat {
      return sqrt(distanceSquared(from: from))
  }
  
}
