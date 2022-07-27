//
//  ScannerModule.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 20/07/2022.
//

import UIKit
import AVFoundation

class ScannerModule {
  
  static func start(navigationController: UINavigationController,
                    acceptedResultTypes: [ScanResultType] = ScanResultType.allCases,
                    defaultScanMode: ScanMode = .qr,
                    scanModes: [ScanMode] = [.qr, .text],
                    onComplete: @escaping (String, ScanResultType) -> Void) {
    
    func moveToScanner() {
      let vc = KrystalScannerViewController.instantiateFromNib()
      vc.onScanSuccess = onComplete
      vc.acceptedResults = acceptedResultTypes
      vc.defaultScanMode = defaultScanMode
      vc.availableScanModes = scanModes
      vc.hidesBottomBarWhenPushed = true
      navigationController.pushViewController(vc, animated: true)
    }
    
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      DispatchQueue.main.async {
        moveToScanner()
      }
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          DispatchQueue.main.async {
            moveToScanner()
          }
        }
      }
    case .denied:
      _ = KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: navigationController)
    case .restricted:
      return
    }
    
  }
  
}
