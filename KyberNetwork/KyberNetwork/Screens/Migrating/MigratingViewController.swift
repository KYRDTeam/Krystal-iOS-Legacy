//
//  MigratingViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 17/08/2022.
//

import UIKit

class MigratingViewController: UIViewController {
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var continueButton: UIButton!
  
  var appMigrationManager: AppMigrationManager?
  var migrationCompleted: (() -> ())?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupViews()
  }
  
  func setupViews() {
    progressView.isHidden = true
    
    continueButton.setBackgroundColor(.Kyber.primaryGreenColor, forState: .normal)
    continueButton.setBackgroundColor(.Kyber.evenBg, forState: .disabled)
    continueButton.setTitleColor(.black, for: .normal)
    continueButton.setTitleColor(.white.withAlphaComponent(0.3), for: .disabled)
  }
  
  func startMigration() {
    appMigrationManager?.execute(progressCallback: { progress in
      DispatchQueue.main.async {
        UIView.animate(withDuration: 0.2) {
          self.progressView.setProgress(progress, animated: true)
        }
      }
    }, completion: {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self.migrationCompleted?()
      }
    })
  }
  
  @IBAction func continueWasTapped(_ sender: Any) {
    continueButton.isEnabled = false
    progressView.isHidden = false
    startMigration()
  }
  
}
