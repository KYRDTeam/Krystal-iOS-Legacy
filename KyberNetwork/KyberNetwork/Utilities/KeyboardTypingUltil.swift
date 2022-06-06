//
//  KeyboardUltil.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/05/2022.
//

import Foundation

class KeyboardTypingUtil {
  var action: (() -> Void)?
  var keyboardTimer: Timer?
  
  func start() {
    self.stop()
    self.keyboardTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(KeyboardTypingUtil.keyboardPauseTyping),
            userInfo: nil,
            repeats: false
    )
  }
  
  func stop() {
    self.keyboardTimer?.invalidate()
  }
  
  @objc func keyboardPauseTyping(timer: Timer) {
    self.action?()
  }
}
