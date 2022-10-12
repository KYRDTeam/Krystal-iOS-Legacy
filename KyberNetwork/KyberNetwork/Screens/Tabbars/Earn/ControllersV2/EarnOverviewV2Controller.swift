//
//  EarnOverviewV2Controller.swift
//  KyberNetwork
//
//  Created by Com1 on 11/10/2022.
//

import UIKit

class EarnOverviewV2Controller: InAppBrowsingViewController {
  @IBOutlet weak var segmentedControl: SegmentedControl!
  @IBOutlet weak var pageContainer: UIView!
  let pageViewController: UIPageViewController = {
    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    return pageVC
  }()
  
  var childListViewControllers: [InAppBrowsingViewController] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    initChildViewControllers()
    setupUI()
    setupPageViewController()
  }
  
  func initChildViewControllers() {
    let earnPoolVC = EarnListViewController.instantiateFromNib()
    let portfolioVC = StakingPortfolioViewController.instantiateFromNib()
    childListViewControllers = [earnPoolVC, portfolioVC]
  }

  func setupUI() {
    segmentedControl.highlightSelectedSegment(width: 32)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.setWidth(UIScreen.main.bounds.size.width / 3, forSegmentAt: 0)
    segmentedControl.setWidth(UIScreen.main.bounds.size.width / 3, forSegmentAt: 1)
    segmentedControl.setWidth(UIScreen.main.bounds.size.width / 3, forSegmentAt: 2)
  }
  
  func setupPageViewController() {
    let defaultPageIndex = 0
    pageViewController.view.frame = self.pageContainer.bounds
    pageViewController.setViewControllers([childListViewControllers[defaultPageIndex]], direction: .forward, animated: true)
    pageViewController.dataSource = self
    pageContainer.addSubview(pageViewController.view)
    addChild(pageViewController)
    pageViewController.didMove(toParent: self)
//    removeSwipeGesture()
  }
  
  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    segmentedControl.underlineCenterPosition()
  }
}

extension EarnOverviewV2Controller: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    if let vc = viewController as? InAppBrowsingViewController, let index = childListViewControllers.index(of: vc) {
      if index + 1 < childListViewControllers.count {
        return childListViewControllers[index + 1]
      }
    }
    return nil
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    if let vc = viewController as? InAppBrowsingViewController, let index = childListViewControllers.index(of: vc) {
      if index - 1 >= 0 {
        return childListViewControllers[index - 1]
      }
    }
    return nil
  }
}
