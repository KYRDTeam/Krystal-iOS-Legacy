//
//  Copyright (c) 2021 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AVFoundation
import CoreVideo
import MLKit
import UIKit

//* Provides image related utility APIs.
#if __ARM_NEON__
#endif

//* `CIContext` to render pixel buffer to images.
private var gCIContext: CIContext!

/// Defines UI-related utilitiy methods for text recognition.
public class OCRUtilities {
  
  // MARK: - Public
  
  public static func imageOrientation(
    fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
  ) -> UIImage.Orientation {
    var deviceOrientation = UIDevice.current.orientation
    if deviceOrientation == .faceDown || deviceOrientation == .faceUp
        || deviceOrientation
        == .unknown
    {
      deviceOrientation = currentUIOrientation()
    }
    switch deviceOrientation {
    case .portrait:
      return devicePosition == .front ? .leftMirrored : .right
    case .landscapeLeft:
      return devicePosition == .front ? .downMirrored : .up
    case .portraitUpsideDown:
      return devicePosition == .front ? .rightMirrored : .left
    case .landscapeRight:
      return devicePosition == .front ? .upMirrored : .down
    case .faceDown, .faceUp, .unknown:
      return .up
    @unknown default:
      fatalError()
    }
  }
  /// Converts a `UIImage` to an image buffer.
  ///
  /// @param image The `UIImage` which should be converted.
  /// @return The image buffer. Callers own the returned buffer and are responsible for releasing it
  ///     when it is no longer needed. Additionally, the image orientation will not be accounted for
  ///     in the returned buffer, so callers must keep track of the orientation separately.
  public static func createImageBuffer(from image: UIImage) -> CVImageBuffer? {
    guard let cgImage = image.cgImage else { return nil }
    let width = cgImage.width
    let height = cgImage.height
    
    var buffer: CVPixelBuffer? = nil
    CVPixelBufferCreate(
      kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil,
      &buffer)
    guard let imageBuffer = buffer else { return nil }
    
    let flags = CVPixelBufferLockFlags(rawValue: 0)
    CVPixelBufferLockBaseAddress(imageBuffer, flags)
    let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
    let context = CGContext(
      data: baseAddress, width: width, height: height, bitsPerComponent: 8,
      bytesPerRow: bytesPerRow, space: colorSpace,
      bitmapInfo: (CGImageAlphaInfo.premultipliedFirst.rawValue
                   | CGBitmapInfo.byteOrder32Little.rawValue))
    
    if let context = context {
      let rect = CGRect.init(x: 0, y: 0, width: width, height: height)
      context.draw(cgImage, in: rect)
      CVPixelBufferUnlockBaseAddress(imageBuffer, flags)
      return imageBuffer
    } else {
      CVPixelBufferUnlockBaseAddress(imageBuffer, flags)
      return nil
    }
  }
  
  /// Returns a color interpolated between to other colors.
  ///
  /// - Parameters:
  ///   - fromColor: The start color of the interpolation.
  ///   - toColor: The end color of the interpolation.
  ///   - ratio: The ratio in range [0, 1] by which the colors should be interpolated. Passing 0
  ///         results in `fromColor` and passing 1 results in `toColor`, whereas passing 0.5 results
  ///         in a color that is half-way between `fromColor` and `startColor`. Values are clamped
  ///         between 0 and 1.
  /// - Returns: The interpolated color.
  private static func interpolatedColor(
    fromColor: UIColor, toColor: UIColor, ratio: CGFloat
  ) -> UIColor {
    var fromR: CGFloat = 0
    var fromG: CGFloat = 0
    var fromB: CGFloat = 0
    var fromA: CGFloat = 0
    fromColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
    
    var toR: CGFloat = 0
    var toG: CGFloat = 0
    var toB: CGFloat = 0
    var toA: CGFloat = 0
    toColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
    
    let clampedRatio = max(0.0, min(ratio, 1.0))
    
    let interpolatedR = fromR + (toR - fromR) * clampedRatio
    let interpolatedG = fromG + (toG - fromG) * clampedRatio
    let interpolatedB = fromB + (toB - fromB) * clampedRatio
    let interpolatedA = fromA + (toA - fromA) * clampedRatio
    
    return UIColor(
      red: interpolatedR, green: interpolatedG, blue: interpolatedB, alpha: interpolatedA)
  }
  
  /// Returns the distance between two 3D points.
  ///
  /// - Parameters:
  ///   - fromPoint: The starting point.
  ///   - endPoint: The end point.
  /// - Returns: The distance.
  private static func distance(fromPoint: Vision3DPoint, toPoint: Vision3DPoint) -> CGFloat {
    let xDiff = fromPoint.x - toPoint.x
    let yDiff = fromPoint.y - toPoint.y
    let zDiff = fromPoint.z - toPoint.z
    return CGFloat(sqrt(xDiff * xDiff + yDiff * yDiff + zDiff * zDiff))
  }
  
  // MARK: - Private
  
  private static func currentUIOrientation() -> UIDeviceOrientation {
    let deviceOrientation = { () -> UIDeviceOrientation in
      switch UIApplication.shared.statusBarOrientation {
      case .landscapeLeft:
        return .landscapeRight
      case .landscapeRight:
        return .landscapeLeft
      case .portraitUpsideDown:
        return .portraitUpsideDown
      case .portrait, .unknown:
        return .portrait
      @unknown default:
        fatalError()
      }
    }
    guard Thread.isMainThread else {
      var currentOrientation: UIDeviceOrientation = .portrait
      DispatchQueue.main.sync {
        currentOrientation = deviceOrientation()
      }
      return currentOrientation
    }
    return deviceOrientation()
  }
  
  /**
   * Crops `CMSampleBuffer` to a specified rect. This will not alter the original data. Currently this
   * method only handles `CMSampleBufferRef` with RGB color space.
   *
   * @param sampleBuffer The original `CMSampleBuffer`.
   * @param rect The rect to crop to.
   * @return A `CMSampleBuffer` cropped to the given rect.
   */
  class func croppedSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                 with rect: CGRect) -> CMSampleBuffer? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    
    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
    
    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
    let width = CVPixelBufferGetWidth(imageBuffer)
    let bytesPerPixel = bytesPerRow / width
    guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else { return nil }
    let baseAddressStart = baseAddress.assumingMemoryBound(to: UInt8.self)
    
    var cropX = Int(rect.origin.x)
    let cropY = Int(rect.origin.y)
    
    // Start pixel in RGB color space can't be odd.
    if cropX % 2 != 0 {
      cropX += 1
    }
    
    let cropStartOffset = Int(cropY * bytesPerRow + cropX * bytesPerPixel)
    
    var pixelBuffer: CVPixelBuffer!
    var error: CVReturn
    
    // Initiates pixelBuffer.
    let pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
    let options = [
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
      kCVPixelBufferWidthKey: rect.size.width,
      kCVPixelBufferHeightKey: rect.size.height
    ] as [CFString : Any]
    
    error = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                         Int(rect.size.width),
                                         Int(rect.size.height),
                                         pixelFormat,
                                         &baseAddressStart[cropStartOffset],
                                         Int(bytesPerRow),
                                         nil,
                                         nil,
                                         options as CFDictionary,
                                         &pixelBuffer)
    if error != kCVReturnSuccess {
      print("Crop CVPixelBufferCreateWithBytes error \(Int(error))")
      return nil
    }
    
    // Cropping using CIImage.
    var ciImage = CIImage(cvImageBuffer: imageBuffer)
    ciImage = ciImage.cropped(to: rect)
    // CIImage is not in the original point after cropping. So we need to pan.
    ciImage = ciImage.transformed(by: CGAffineTransform(translationX: CGFloat(-cropX), y: CGFloat(-cropY)))
    
    gCIContext.render(ciImage, to: pixelBuffer!)
    
    // Prepares sample timing info.
    var sampleTime = CMSampleTimingInfo()
    sampleTime.duration = CMSampleBufferGetDuration(sampleBuffer)
    sampleTime.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    sampleTime.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
    
    var videoInfo: CMVideoFormatDescription!
    error = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
    if error != kCVReturnSuccess {
      print("CMVideoFormatDescriptionCreateForImageBuffer error \(Int(error))")
      CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
      return nil
    }
    
    // Creates `CMSampleBufferRef`.
    var resultBuffer: CMSampleBuffer?
    error = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                               imageBuffer: pixelBuffer,
                                               dataReady: true,
                                               makeDataReadyCallback: nil,
                                               refcon: nil,
                                               formatDescription: videoInfo,
                                               sampleTiming: &sampleTime,
                                               sampleBufferOut: &resultBuffer)
    if error != kCVReturnSuccess {
      print("CMSampleBufferCreateForImageBuffer error \(Int(error))")
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
    return resultBuffer
  }
  
}

extension OCRUtilities {

  final class func doBadSwizzleStuff() {
    guard gCIContext == nil else { return }
    guard let defaultDevice = MTLCreateSystemDefaultDevice() else { return }
    gCIContext = CIContext(mtlDevice: defaultDevice)
  }
}

// MARK: - Extension

extension CGRect {
  /// Returns a `Bool` indicating whether the rectangle's values are valid`.
  func isValid() -> Bool {
    return
    !(origin.x.isNaN || origin.y.isNaN || width.isNaN || height.isNaN || width < 0 || height < 0)
  }
}
