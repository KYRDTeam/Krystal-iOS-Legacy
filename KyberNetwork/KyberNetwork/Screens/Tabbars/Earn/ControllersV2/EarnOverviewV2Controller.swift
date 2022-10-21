//
//  EarnOverviewV2Controller.swift
//  KyberNetwork
//
//  Created by Com1 on 11/10/2022.
//

import UIKit
import BaseModule

class EarnOverviewV2Controller: InAppBrowsingViewController {
  @IBOutlet weak var segmentedControl: SegmentedControl!
  @IBOutlet weak var pageContainer: UIView!
  @IBOutlet weak var dotView: UIView!
  var selectedPageIndex = 0
  let pageViewController: UIPageViewController = {
    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    return pageVC
  }()
  
  var childListViewControllers: [InAppBrowsingViewController] = []
  var viewModel: EarnOverViewModel
  override var supportAllChainOption: Bool {
    return true
  }
  init(viewModel: EarnOverViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnOverviewV2Controller.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initChildViewControllers()
    
    setupUI()
    setupPageViewController()
  }
  
  @objc override func onAppSwitchChain() {
    super.onAppSwitchChain()
    viewModel.appDidSwitchChain()
  }
  
  func initChildViewControllers() {
    let earnPoolVC = EarnListViewController.instantiateFromNib()
    let portfolioVC = StakingPortfolioViewController.instantiateFromNib()
    childListViewControllers = [earnPoolVC, portfolioVC]
  }

  func setupUI() {
    segmentedControl.highlightSelectedSegment(width: 100)
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
    segmentedControl.setWidth(segmentedControl.frame.size.width / 2, forSegmentAt: 0)
    segmentedControl.setWidth(segmentedControl.frame.size.width / 2, forSegmentAt: 1)
  }

  func setupPageViewController() {
    pageViewController.view.frame = self.pageContainer.bounds
    pageViewController.setViewControllers([childListViewControllers[selectedPageIndex]], direction: .forward, animated: true)
    pageViewController.dataSource = self
    pageViewController.delegate = self
    pageContainer.addSubview(pageViewController.view)
    addChild(pageViewController)
    pageViewController.didMove(toParent: self)
  }
  
  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    segmentedControl.underlineCenterPosition()
    if sender.selectedSegmentIndex != selectedPageIndex {
      let direction: UIPageViewController.NavigationDirection = sender.selectedSegmentIndex < selectedPageIndex ? .reverse : .forward
      selectedPageIndex = sender.selectedSegmentIndex
      pageViewController.setViewControllers([childListViewControllers[sender.selectedSegmentIndex]], direction: direction, animated: true)
    }
  }
  
  @IBAction func historyButtonWasTapped(_ sender: Any) {
    viewModel.didTapHistoryButton()
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

extension EarnOverviewV2Controller: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    var newIndex = 0
    if pageViewController.viewControllers?.first is StakingPortfolioViewController {
      newIndex = 1
    }
  
    segmentedControl.selectedSegmentIndex = newIndex
    selectedPageIndex = newIndex
    segmentedControl.underlineCenterPosition()
  }
}
