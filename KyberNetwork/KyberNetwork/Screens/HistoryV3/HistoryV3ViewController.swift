//
//  HistoryV3ViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 22/12/2022.
//

import UIKit
import BaseModule
import TransactionModule
import DesignSystem
import AppState
import Dependencies

class HistoryV3ViewController: BaseWalletOrientedViewController {
    
    @IBOutlet weak var statsButton: UIButton!
    @IBOutlet weak var segmentControl: DesignSystem.SegmentedControl!
    @IBOutlet weak var pageContainer: UIView!
    @IBOutlet weak var segmentControlTrailingConstant: NSLayoutConstraint!
    
    var selectedPageIndex = 0
    var viewControllers: [UIViewController] = []
    let pageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        return pageVC
    }()
    
    override var supportAllChainOption: Bool {
        return true
    }
    
    override var currentChain: ChainType {
        return selectedChain
    }
    
    override var supportSolana: Bool {
        return false
    }
    
    var hasPendingTx: Bool {
        return TransactionManager.txProcessor.hasPendingTx()
    }
    
    var isHistoryStatsEnabled: Bool {
        return AppDependencies.featureFlag.isFeatureEnabled(key: FeatureFlagKeys.historyStats)
    }
    
    var segmentControlTrailingSpace: CGFloat {
        return isHistoryStatsEnabled ? 56 : 16
    }
    
    var selectedChain: ChainType = AppState.shared.isSelectedAllChain ? .all : AppState.shared.currentChain
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        super.onAppSwitchChain()
        segmentControlTrailingConstant.constant = -segmentControlTrailingSpace
        statsButton.isHidden = !isHistoryStatsEnabled
        setupPageController()
        setupSegmentControl()
        
        if hasPendingTx {
            jumpToPage(index: 1)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MixPanelManager.track("history_open", properties: ["screenid": "history"])
    }
    
    override func onAppSelectAllChain() {
        selectedChain = .all
        super.onAppSelectAllChain()
    }
    
    override func onAppSwitchChain() {
        selectedChain = AppState.shared.currentChain
        reloadChain()
    }
    
    func setupPageController() {
        let historyVC = HistoryCoordinator.createHistoryViewController(chain: selectedChain)
        
        let pendingViewModel = PendingTxViewModel()
        let pendingVC = PendingTxViewController.instantiateFromNib()
        pendingVC.viewModel = pendingViewModel
        
        viewControllers = [historyVC, pendingVC]
        
        pageViewController.view.frame = self.pageContainer.bounds
        pageViewController.setViewControllers([viewControllers[selectedPageIndex]], direction: .forward, animated: true)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageContainer.addSubview(pageViewController.view)
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        removeSwipeGesture()
    }
    
    func removeSwipeGesture() {
        for view in pageViewController.view.subviews {
            if let subView = view as? UIScrollView {
                subView.isScrollEnabled = false
            }
        }
    }
    
    func setupSegmentControl() {
        let width = UIScreen.main.bounds.width - segmentControlTrailingSpace - 16
        segmentControl.backgroundColor = .clear
        segmentControl.tintColor = AppTheme.current.primaryColor
        segmentControl.frame = CGRect(x: self.segmentControl.frame.minX,
                                      y: self.segmentControl.frame.minY,
                                      width: segmentControl.frame.width, height: 30)
        segmentControl.setWidth(width / 2, forSegmentAt: 0)
        segmentControl.setWidth(width / 2, forSegmentAt: 1)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.setTitleTextAttributes([.font: UIFont.karlaReguler(ofSize: 16)], for: .normal)
        segmentControl.highlightSelectedSegment(parentWidth: width, width: width / 2)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        segmentControl.underlineCenterPosition()
        if sender.selectedSegmentIndex != selectedPageIndex {
            selectPage(index: sender.selectedSegmentIndex)
        }
    }
    
    func jumpToPage(index: Int) {
        segmentControl.selectedSegmentIndex = index
        segmentControl.underlineCenterPosition(parentWidth: UIScreen.main.bounds.width - segmentControlTrailingSpace - 16)
        if index != selectedPageIndex {
            selectPage(index: index)
        }
    }
    
    func selectPage(index: Int) {
        let direction: UIPageViewController.NavigationDirection = index < selectedPageIndex ? .reverse : .forward
        selectedPageIndex = index
        pageViewController.setViewControllers([viewControllers[index]], direction: direction, animated: true)
    }
    
    @IBAction func statsTapped(_ sender: Any) {
        let viewModel = HistoryStatsViewModel(chain: currentChain, address: AppState.shared.currentAddress.addressString)
        let vc = HistoryStatsViewController.instantiateFromNib()
        vc.viewModel = viewModel
        vc.view.layoutIfNeeded()
        let popup = PopupViewController(vc: vc, configuration: PopupConfiguration(height: .intrinsic))
        present(popup, animated: true)
    }
    
}

extension HistoryV3ViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.index(of: viewController) {
            if index + 1 < viewControllers.count {
                return viewControllers[index + 1]
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.index(of: viewController) {
            if index - 1 >= 0 {
                return viewControllers[index - 1]
            }
        }
        return nil
    }
}

extension HistoryV3ViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
    }
}
