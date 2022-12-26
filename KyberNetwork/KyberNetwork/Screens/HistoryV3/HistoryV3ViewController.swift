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

class HistoryV3ViewController: BaseWalletOrientedViewController {
    
    @IBOutlet weak var segmentControl: SegmentedControl!
    @IBOutlet weak var pageContainer: UIView!
    
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
    
    var selectedChain: ChainType = .all
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPageController()
        setupSegmentControl()
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
        let historyVC = HistoryCoordinator.createHistoryViewController()
        let pendingVC = UIViewController()
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
        let width = UIScreen.main.bounds.size.width - 32
        segmentControl.backgroundColor = .clear
        segmentControl.tintColor = AppTheme.current.primaryColor
        segmentControl.frame = CGRect(x: self.segmentControl.frame.minX,
                                      y: self.segmentControl.frame.minY,
                                      width: segmentControl.frame.width, height: 30)
        segmentControl.setWidth(width / 2, forSegmentAt: 0)
        segmentControl.setWidth(width / 2, forSegmentAt: 1)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.setTitleTextAttributes([.font: UIFont.karlaReguler(ofSize: 16)], for: .normal)
        segmentControl.highlightSelectedSegment()
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
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
