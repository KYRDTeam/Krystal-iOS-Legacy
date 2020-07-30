// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import FSPagerView
import Kingfisher

enum KNExploreViewEvent {
  case getListMobileBanner
  case openNotification
  case openAlert
  case openHistory
  case openLogin
  case openBannerLink(link: String)
}

class KNExploreViewModel {
  var bannerItems: [[String: String]] = []
}

protocol KNExploreViewControllerDelegate: class {
  func kExploreViewController(_ controller: KNExploreViewController, run event: KNExploreViewEvent)
}

class KNExploreViewController: KNBaseViewController {
  @IBOutlet weak var bannerPagerView: FSPagerView! {
    didSet {
      self.bannerPagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
    }
  }
  @IBOutlet weak var bannerPagerControl: FSPageControl!
  @IBOutlet weak var notificationButton: UIButton!
  @IBOutlet weak var alertButton: UIButton!
  @IBOutlet weak var historyButton: UIButton!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var headerTitleLabel: UILabel!
  @IBOutlet weak var unreadNotiLabel: UILabel!

  var viewModel: KNExploreViewModel
  weak var delegate: KNExploreViewControllerDelegate?

  init(viewModel: KNExploreViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNExploreViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.bannerPagerControl.setFillColor(UIColor.Kyber.orange, for: .selected)
    self.bannerPagerControl.setFillColor(UIColor.Kyber.lightPeriwinkle, for: .normal)
    self.bannerPagerControl.numberOfPages = 0
    self.notificationButton.centerVertically(padding: 10)
    self.alertButton.centerVertically(padding: 10)
    self.historyButton.centerVertically(padding: 10)
    self.loginButton.centerVertically(padding: 10)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.headerTitleLabel.text = "Explore".toBeLocalised()
    self.notificationButton.setTitle("Notifications".toBeLocalised(), for: .normal)
    self.alertButton.setTitle("Alert".toBeLocalised(), for: .normal)
    self.historyButton.setTitle("History".toBeLocalised(), for: .normal)
    self.loginButton.setTitle("profile".toBeLocalised(), for: .normal)
    self.unreadNotiLabel.rounded(radius: 7)
    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.notificationDidUpdate(_:)),
      name: name,
      object: nil
    )
    self.notificationDidUpdate(nil)
    self.delegate?.kExploreViewController(self, run: .getListMobileBanner)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.bannerPagerView.itemSize = self.bannerPagerView.frame.size
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }
  func coordinatorUpdateBannerImages(items: [[String: String]]) {
    self.viewModel.bannerItems = items
    self.bannerPagerControl.numberOfPages = self.viewModel.bannerItems.count
    self.bannerPagerControl.currentPage = 0
    self.bannerPagerView.reloadData()
  }

  @IBAction func menuButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      KNCrashlyticsUtil.logCustomEvent(withName: "explore_notification_tapped", customAttributes: nil)
      self.delegate?.kExploreViewController(self, run: .openNotification)
    case 2:
      KNCrashlyticsUtil.logCustomEvent(withName: "explore_alert_tapped", customAttributes: nil)
      self.delegate?.kExploreViewController(self, run: .openAlert)
    case 3:
      KNCrashlyticsUtil.logCustomEvent(withName: "explore_history_tapped", customAttributes: nil)
      self.delegate?.kExploreViewController(self, run: .openHistory)
    case 4:
      KNCrashlyticsUtil.logCustomEvent(withName: "explore_profile_tapped", customAttributes: nil)
      self.delegate?.kExploreViewController(self, run: .openLogin)
    default:
      break
    }
  }

  @objc func notificationDidUpdate(_ sender: Any?) {
    let numUnread: Int = {
      if IEOUserStorage.shared.user == nil { return 0 }
      return KNNotificationCoordinator.shared.numberUnread
    }()
    self.update(notificationsCount: numUnread)
  }

  func update(notificationsCount: Int) {
    self.unreadNotiLabel.isHidden = notificationsCount == 0
    self.unreadNotiLabel.text = "  \(notificationsCount)  "
  }
}

extension KNExploreViewController: FSPagerViewDataSource {
  public func numberOfItems(in pagerView: FSPagerView) -> Int {
    return self.viewModel.bannerItems.count
  }

  public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
    let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
    let url = URL(string: self.viewModel.bannerItems[index]["image_url"] ?? "")
    cell.imageView?.kf.setImage(with: url)
    cell.imageView?.contentMode = .scaleAspectFill
    cell.imageView?.clipsToBounds = true
    return cell
  }
}

extension KNExploreViewController: FSPagerViewDelegate {
  func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
    pagerView.deselectItem(at: index, animated: true)
    pagerView.scrollToItem(at: index, animated: true)
    if let link = self.viewModel.bannerItems[index]["link"] {
      KNCrashlyticsUtil.logCustomEvent(withName: "explore_click_banner", customAttributes: ["link": link])
      self.delegate?.kExploreViewController(self, run: .openBannerLink(link: link))
    }
  }

  func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
    self.bannerPagerControl.currentPage = targetIndex
  }

  func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
    self.bannerPagerControl.currentPage = pagerView.currentIndex
  }
}
