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
  @IBOutlet weak var draggingNoteView: UIView!
  
  var isDebug = true
  
  let captureSession = AVCaptureSession()
  lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
  let videoDataOutput = AVCaptureVideoDataOutput()
  private lazy var sessionQueue = DispatchQueue(label: "app.krystal.scanner.queue")
  var device: AVCaptureDevice?
  
  // Support drawing
  let borderLayer = CAShapeLayer()
  let maskLayer = CAShapeLayer()
  var lastTouch: CGPoint = .zero
  let minHoleSize: CGFloat = 64
  let maxHoleWidth: CGFloat = UIScreen.main.bounds.width - 48
  var lastHoleFrame: CGRect = .zero
  var isDraggingEnabled = false
  
  var availableScanModes: [ScanMode] = [.qr, .text]
  var acceptedResults: [ScanResultType] = [.walletConnect, .ethPublicKey, .ethPrivateKey, .solPublicKey, .solPrivateKey]
  var detector: TextDetector = BarCodeDetector()
  var onScanSuccess: ((_ text: String, _ type: ScanResultType) -> ())?
  
  var scanMode: ScanMode = .qr {
    didSet {
      self.titleLabel.text = self.title(forMode: scanMode)
      switch scanMode {
      case .qr:
        draggingNoteView.isHidden = true
        isDraggingEnabled = false
        detector = BarCodeDetector()
      case .text:
        draggingNoteView.isHidden = false
        isDraggingEnabled = true
        detector = OcrDetector()
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupViews()
    self.setupSegmentView()
    self.showCameraFeed()
    self.setCameraOutput()
    self.setCameraInput()
  }
  
  override func loadView() {
    super.loadView()
    
    self.view.backgroundColor = .white // Fix bug lagging when push, don't know why
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    self.captureSession.startRunning()
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
    
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    holeCover.addGestureRecognizer(panGesture)
  }
  
  func title(forMode scanMode: ScanMode) -> String {
    switch scanMode {
    case .qr:
      return Strings.scanQRCode
    case .text:
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
      case .text:
        let height = width / 2
        self.holeCover.holeFrame = .init(x: self.view.frame.midX - width / 2,
                                         y: self.view.frame.midY - height / 2,
                                         width: width, height: height)
      }
    }
  }
  
  private func setCameraInput() {
    weak var weakSelf = self
    sessionQueue.async {
      guard let strongSelf = weakSelf else {
        print("Self is nil!")
        return
      }
      let cameraPosition: AVCaptureDevice.Position = .back
      guard let device = strongSelf.captureDevice(forPosition: cameraPosition) else {
        print("Failed to get capture device for camera position: \(cameraPosition)")
        return
      }
      self.device = device
      do {
        strongSelf.captureSession.beginConfiguration()
        let currentInputs = strongSelf.captureSession.inputs
        for input in currentInputs {
          strongSelf.captureSession.removeInput(input)
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        guard strongSelf.captureSession.canAddInput(input) else {
          print("Failed to add capture session input.")
          return
        }
        strongSelf.captureSession.addInput(input)
        strongSelf.captureSession.commitConfiguration()
      } catch {
        print("Failed to create capture device input: \(error.localizedDescription)")
      }
    }
  }
  
  private func showCameraFeed() {
    self.previewLayer.videoGravity = .resizeAspectFill
    self.previewView.layer.addSublayer(self.previewLayer)
    self.previewLayer.frame = self.previewView.frame
  }
  
  private func setCameraOutput() {
    weak var weakSelf = self
    sessionQueue.async {
      guard let strongSelf = weakSelf else {
        print("Self is nil!")
        return
      }
      strongSelf.captureSession.beginConfiguration()
      // When performing latency tests to determine ideal capture settings,
      // run the app in 'release' mode to get accurate performance metrics
      strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
      
      let output = AVCaptureVideoDataOutput()
      output.videoSettings = [
        (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
      ]
      output.alwaysDiscardsLateVideoFrames = true
      
      let outputQueue = DispatchQueue(label: "app.krystal.scanner.output")
      output.setSampleBufferDelegate(strongSelf, queue: outputQueue)
      guard strongSelf.captureSession.canAddOutput(output) else {
        print("Failed to add capture session output.")
        return
      }
      strongSelf.captureSession.addOutput(output)
      strongSelf.captureSession.commitConfiguration()
    }
  }
  
  private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    let discoverySession = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: .video,
      position: .back
    )
    return discoverySession.devices.first { $0.position == position }
  }
  
}

extension KrystalScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  
  private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer, videoOrientation: AVCaptureVideoOrientation) -> CGImage? {
    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      let context = CIContext()
      var ciImage = CIImage(cvPixelBuffer: imageBuffer)
      
      if videoOrientation == .landscapeLeft {
        ciImage = ciImage.oriented(forExifOrientation: 3)
      } else if videoOrientation == .landscapeRight {
        ciImage = ciImage.oriented(forExifOrientation: 1)
      } else if videoOrientation == .portrait {
        ciImage = ciImage.oriented(forExifOrientation: 6)
      } else if videoOrientation == .portraitUpsideDown {
        ciImage = ciImage.oriented(forExifOrientation: 8)
      }
      
      return context.createCGImage(ciImage, from: ciImage.extent)
    }
    
    return nil
  }
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if device?.isAdjustingFocus ?? true {
      return
    }
    
    guard var cgImage = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer, videoOrientation: .portrait) else {
      return
    }
    if scanMode == .text {
      guard let croppedImage = cropDetectingFrame(cgImage: cgImage, inRect: self.holeCover.holeFrame) else {
        return
      }
      cgImage = croppedImage
    }
    detector.detect(cgImage: cgImage) { [weak self] texts in
      self?.processScanResult(texts: texts)
    }
  }
  
  private func cropDetectingFrame(cgImage: CGImage, inRect rect: CGRect) -> CGImage? {
    let imageWidth = CGFloat(cgImage.width)
    let imageHeight = CGFloat(cgImage.height)
    
    let scale = imageHeight / UIScreen.main.bounds.height
    let frameWidth = holeCover.holeFrame.width * scale
    let frameHeigth = holeCover.holeFrame.height * scale
    let cropFrame = CGRect(x: imageWidth / 2 - frameWidth / 2,
                           y: imageHeight / 2 - frameHeigth / 2,
                           width: frameWidth,
                           height: frameHeigth)
    
    return cgImage.cropping(to: cropFrame)
  }
  
  func processScanResult(texts: [String]) {
    for text in texts {
      if let type = ScannerUtils.getResultType(ofText: text), acceptedResults.contains(type) {
        handleValidResult(text: ScannerUtils.smoothen(text: text, forType: type), type: type)
        break
      }
    }
  }
  
  func handleValidResult(text: String, type: ScanResultType) {
    DispatchQueue.main.async {
      self.captureSession.stopRunning()
      self.navigationController?.popViewController(animated: true, completion: { [weak self] in
        self?.onScanSuccess?(text, type)
      })
      
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
