//
//  NotificationV2ViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import UIKit

enum NotificationFilterTag {
  case all
  case unread
  
  var type: NotificationType? {
    return nil
  }
  
  var status: NotificationStatus? {
    switch self {
    case .all:
      return nil
    case .unread:
      return .unread
    }
  }
  
  var title: String {
    switch self {
    case .all:
      return Strings.all
    case .unread:
      return Strings.unread
    }
  }
}

class NotificationV2ViewController: UIViewController {
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var pageViewContainer: UIView!
  var pageController: UIPageViewController!
  
  var filterTags: [NotificationFilterTag] = [.all, .unread]
  var controllers: [NotificationListViewController] = []
  var selectingFilterTagIndex: Int = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupFilterCollectionView()
    setupPageViewControllers()
  }
  
  func setupFilterCollectionView() {
    collectionView.registerCellNib(NotificationFilterTagCell.self)
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  func setupPageViewControllers() {
    pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    pageController.delegate = self
    pageController.dataSource = self
    addChild(pageController)
    pageViewContainer.addSubview(pageController.view)
    pageController.view.frame = pageViewContainer.bounds
    controllers = filterTags.map { tag in
      let viewModel = NotificationListViewModel(type: tag.type, status: tag.status)
      let viewController = NotificationListViewController.instantiateFromNib()
      viewController.viewModel = viewModel
      viewController.delegate = self
      return viewController
    }
    pageController.setViewControllers([controllers[0]], direction: .forward, animated: false)
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func readAllWasTapped(_ sender: Any) {
    controllers[selectingFilterTagIndex].viewModel.readAll()
    controllers.forEach {
      $0.readAll()
    }
  }
  
}

extension NotificationV2ViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
  
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if completed {
      if let currentViewController = pageViewController.viewControllers?.first as? NotificationListViewController,
         let index = controllers.index(of: currentViewController) {
        selectingFilterTagIndex = index
        collectionView.reloadData()
      }
    }
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let vc = viewController as? NotificationListViewController else { return nil }
    if let index = controllers.firstIndex(of: vc) {
      if index < controllers.count - 1 {
        return controllers[index + 1]
      } else {
        return nil
      }
    }
    return nil
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let vc = viewController as? NotificationListViewController else { return nil }
    if let index = controllers.firstIndex(of: vc) {
      if index > 0 {
        return controllers[index - 1]
      } else {
        return nil
      }
    }
    return nil
  }
  
}

extension NotificationV2ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return .init(width: 78, height: collectionView.frame.height)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return .init(top: 0, left: 16, bottom: 0, right: 0)
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return filterTags.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(NotificationFilterTagCell.self, indexPath: indexPath)!
    cell.configure(title: filterTags[indexPath.item].title, isSelecting: indexPath.item == selectingFilterTagIndex)
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if selectingFilterTagIndex != indexPath.item {
      pageController.setViewControllers([controllers[indexPath.item]],
                                        direction: indexPath.item > selectingFilterTagIndex ? .forward : .reverse,
                                        animated: true)
      selectingFilterTagIndex = indexPath.item
      collectionView.reloadData()
    }
  }
  
}

extension NotificationV2ViewController: NotificationListViewControllerDelegate {
  
  func onSelectNotification(id: Int) {
    controllers.forEach {
      $0.readNotification(id: id)
    }
  }
  
}
