// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNLandingPageViewEvent {
  case openCreateWallet
  case openImportWallet
  case openTermAndCondition
  case openMigrationAlert
  case getStarted
}

protocol KNLandingPageViewControllerDelegate: class {
  func landinagePageViewController(_ controller: KNLandingPageViewController, run event: KNLandingPageViewEvent)
}

class KNLandingPageViewController: KNBaseViewController {
  let collectionViewLeadTrailPadding = CGFloat(20)
  weak var delegate: KNLandingPageViewControllerDelegate?
  @IBOutlet weak var welcomeScreenCollectionView: KNWelcomeScreenCollectionView!
  @IBOutlet weak var createWalletButton: UIButton!
  @IBOutlet weak var forwardView: UIView!
  @IBOutlet weak var backwardView: UIView!
  var isBrowsingEnable: Bool = true
  override func viewDidLoad() {
    super.viewDidLoad()
    self.createWalletButton.rounded(radius: 16)
    self.updateUI()
    self.observeFeatureFlagChanged()
    configGesture()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
    
    func configGesture() {
        let longGestureFoward = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longGestureFoward.minimumPressDuration = 0.1
        let longGestureBackward = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longGestureBackward.minimumPressDuration = 0.1

        let tapFowardGesture = UITapGestureRecognizer(target: self, action: #selector(tappedFoward))
        let tappedBackwardGesture = UITapGestureRecognizer(target: self, action: #selector(tappedBackward))

        let swipeRightGestureFoward = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeRight))
        swipeRightGestureFoward.direction = .right
        
        let swipeLeftGestureFoward = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeLeft))
        swipeLeftGestureFoward.direction = .left

        let swipeRightGestureBackward = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeRight))
        swipeRightGestureBackward.direction = .right
        
        let swipeLeftGestureBackward = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeLeft))
        swipeLeftGestureBackward.direction = .left
        
        forwardView.addGestureRecognizer(longGestureFoward)
        backwardView.addGestureRecognizer(longGestureBackward)
        
        forwardView.addGestureRecognizer(tapFowardGesture)
        backwardView.addGestureRecognizer(tappedBackwardGesture)
        
        forwardView.addGestureRecognizer(swipeRightGestureFoward)
        forwardView.addGestureRecognizer(swipeLeftGestureFoward)
        
        backwardView.addGestureRecognizer(swipeRightGestureBackward)
        backwardView.addGestureRecognizer(swipeLeftGestureBackward)
    }

    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            welcomeScreenCollectionView.resume()
        } else if sender.state == .began {
            welcomeScreenCollectionView.pause()
        }
    }
    
    @objc func tappedFoward(sender: UILongPressGestureRecognizer) {
        welcomeScreenCollectionView.forward()
    }
    
    @objc func tappedBackward(sender: UILongPressGestureRecognizer) {
        welcomeScreenCollectionView.backward()
    }
    
    @objc func onSwipeRight(sender: UISwipeGestureRecognizer) {
        welcomeScreenCollectionView.backward()
    }
    
    @objc func onSwipeLeft(sender: UISwipeGestureRecognizer) {
        welcomeScreenCollectionView.forward()
    }
  
  func observeFeatureFlagChanged() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reloadMenuItems),
      name: Notification.Name(kUpdateFeatureFlag),
      object: nil
    )
  }
  
  @objc func reloadMenuItems() {
    self.isBrowsingEnable = FeatureFlagManager.shared.showFeature(forKey: FeatureFlagKeys.appBrowsing)
    updateUI()
  }
  
  func updateUI() {
    if self.isBrowsingEnable {
      self.createWalletButton.setTitle(Strings.letsGo, for: .normal)
    } else {
      self.createWalletButton.setTitle(Strings.createWallet, for: .normal)
    }
  }

  @IBAction func createWalletButtonPressed(_ sender: Any) {
    if self.isBrowsingEnable {
      self.delegate?.landinagePageViewController(self, run: .getStarted)
    } else {
      self.delegate?.landinagePageViewController(self, run: .openCreateWallet)
    }
  }

  @IBAction func importWalletButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openImportWallet)
  }

  @IBAction func termAndConditionButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openTermAndCondition)
  }
}
