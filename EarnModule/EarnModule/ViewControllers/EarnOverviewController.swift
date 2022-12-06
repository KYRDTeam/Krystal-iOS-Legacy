//
//  EarnOverviewController.swift
//  EarnModule
//
//  Created by Com1 on 25/10/2022.
//

import UIKit
import BaseModule
import Dependencies
import AppState
import DesignSystem
import Services
import BigInt
import TransactionModule

class EarnOverviewController: InAppBrowsingViewController {
  @IBOutlet weak var segmentedControl: SegmentedControl!
  @IBOutlet weak var pageContainer: UIView!
  @IBOutlet weak var dotView: UIView!
  var selectedPageIndex = 0
  let pageViewController: UIPageViewController = {
    let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    return pageVC
  }()
  
  var childListViewControllers: [InAppBrowsingViewController] = []
  var viewModel: EarnOverViewModel!
  override var supportAllChainOption: Bool {
    return true
  }
  var currentSelectedChain: ChainType = AppState.shared.isSelectedAllChain ? .all : AppState.shared.currentChain

  override func viewDidLoad() {
    super.viewDidLoad()
    initChildViewControllers()

    setupUI()
    setupPageViewController()
  }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDependencies.tracker.track(
            "earn_v2_open",
            properties: ["screenid": "earn_v2"]
        )
    }

  override func onAppSelectAllChain() {
    currentSelectedChain = .all
    reloadAllNetworksChain()
  }

  override func handleChainButtonTapped() {
    AppDependencies.router.openChainList(currentSelectedChain, allowAllChainOption: supportAllChainOption) { [weak self] chain in
      self?.onChainSelected(chain: chain)
    }
  }

  @objc override func onAppSwitchChain() {
    super.onAppSwitchChain()
    currentSelectedChain = AppState.shared.currentChain
//    viewModel.appDidSwitchChain()
  }

  func initChildViewControllers() {
    let earnPoolVC = EarnListViewController.instantiateFromNib()
    earnPoolVC.delegate = self
    let portfolioVC = StakingPortfolioViewController.instantiateFromNib()
    portfolioVC.delegate = self
      earnPoolVC.isSupportEarnv2.observeAndFire(on: self) { value in
          portfolioVC.updateSupportedEarnv2(value)
      }
    childListViewControllers = [earnPoolVC, portfolioVC, InAppBrowsingViewController()]
  }

  func setupUI() {
    if currentSelectedChain == . all {
      reloadAllNetworksChain()
    }
    segmentedControl.highlightSelectedSegment(width: 100)
    let width = UIScreen.main.bounds.size.width - 36
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: width, height: 30)
    segmentedControl.setWidth(width / 3, forSegmentAt: 0)
    segmentedControl.setWidth(width / 3, forSegmentAt: 1)
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
        selectPage(index: sender.selectedSegmentIndex)
    }
  }

  @IBAction func historyButtonWasTapped(_ sender: Any) {
    viewModel.didTapHistoryButton()
  }
    
    func selectPage(index: Int) {
        let direction: UIPageViewController.NavigationDirection = index < selectedPageIndex ? .reverse : .forward
        selectedPageIndex = index
        pageViewController.setViewControllers([childListViewControllers[index]], direction: direction, animated: true)
        AppDependencies.tracker.track( index == 0 ? "mob_earn_earn" : "mob_earn_portfolio", properties: ["screenid": "earn"])
    }
}

extension EarnOverviewController: UIPageViewControllerDataSource {
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

extension EarnOverviewController: UIPageViewControllerDelegate {
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

extension EarnOverviewController: EarnListViewControllerDelegate {
    
    func didSelectPlatform(platform: EarnPlatform, pool: EarnPoolModel) {
        guard let chain = ChainType.make(chainID: pool.chainID) else { return }
        if chain != AppState.shared.currentChain {
            AppState.shared.updateChain(chain: chain)
        }
        let vc = StakingViewController.instantiateFromNib()
        vc.viewModel = StakingViewModel(token: pool.token, platform: platform, chainId: pool.chainID)
        vc.onSelectViewPool = { [weak self] in
            self?.openPortfolio()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func openPortfolio() {
        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.underlineCenterPosition()
        selectPage(index: 1)
    }
}

extension EarnOverviewController: StakingPortfolioViewControllerDelegate {
    func didSelectPlatform(token: Token, platform: EarnPlatform, chainId: Int) {
        guard let chain = ChainType.make(chainID: chainId) else { return }
        if chain != AppState.shared.currentChain {
            AppState.shared.updateChain(chain: chain)
        }
        let vc = StakingViewController.instantiateFromNib()
        vc.viewModel = StakingViewModel(token: token, platform: platform, chainId: chainId)
        vc.onSelectViewPool = { [weak self] in
            self?.openPortfolio()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
