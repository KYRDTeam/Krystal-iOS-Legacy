//
//  KeyboardUltil.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/05/2022.
//

import Foundation

class KeyboardUtil {
  var action: (() -> Void)?
  var keyboardTimer: Timer?
  
  func start() {
    self.stop()
    self.keyboardTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(KeyboardUtil.keyboardPauseTyping),
            userInfo: nil,
            repeats: false
    )
  }
  
  func stop() {
    self.keyboardTimer?.invalidate()
  }
  
  @objc func keyboardPauseTyping(timer: Timer) {
    if let unwrap = self.action {
      unwrap()
    }
  }
}
