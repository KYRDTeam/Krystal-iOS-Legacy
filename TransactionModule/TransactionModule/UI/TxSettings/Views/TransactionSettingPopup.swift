//
//  TransactionSettingPopup.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import UIKit
import Utilities
import FittedSheets
import DesignSystem
import Dependencies
import AppState
import BaseWallet

public class TransactionSettingPopup: UIViewController {
    @IBOutlet weak var segmentControl: SegmentedControl!
    @IBOutlet weak var pageViewContainer: UIView!
    
    var pageController: UIPageViewController!
    var controllers: [UIViewController] = []
    var onConfirmed: ((TxSettingObject) -> ())?
    var onCancelled: (() -> ())?
    var basicTab: TransactionSettingBasicTab!
    var advancedTab: TransactionSettingAdvancedTab!
    var settingObject: TxSettingObject = .default
    var chain: ChainType!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        initViewControllers()
        setupSegmentControl()
        setupPageViewControllers()
        removeSwipeGesture()
    }
    
    func initViewControllers() {
        basicTab = TransactionSettingBasicTab.instantiateFromNib()
        basicTab.viewModel = TransactionSettingBasicTabViewModel(
            settings: settingObject,
            gasConfig: AppDependencies.gasConfig,
            chain: chain
        )
        basicTab.onUpdateSettings = { [weak self] settings in
            self?.settingObject = settings
            self?.advancedTab.updateSettings(settings: settings)
        }
        
        advancedTab = TransactionSettingAdvancedTab.instantiateFromNib()
        advancedTab.viewModel = TransactionSettingAdvancedTabViewModel(
            settings: settingObject,
            gasConfig: AppDependencies.gasConfig,
            chain: chain
        )
        advancedTab.onUpdateSettings = { [weak self] settings in
            self?.settingObject = settings
            self?.basicTab.updateSettings(settings: settings)
        }
        advancedTab.loadViewIfNeeded()
        
        controllers = [basicTab, advancedTab]
    }
    
    func setupSegmentControl() {
        segmentControl.backgroundColor = .clear
        segmentControl.tintColor = AppTheme.current.primaryColor
        segmentControl.frame = CGRect(x: self.segmentControl.frame.minX,
                                      y: self.segmentControl.frame.minY,
                                      width: segmentControl.frame.width, height: 30)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.setTitleTextAttributes([
            .font: UIFont.karlaReguler(ofSize: 16)
        ], for: .normal)
        segmentControl.highlightSelectedSegment()
    }
    
    func setupPageViewControllers() {
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageController.delegate = self
        pageController.dataSource = self
        addChild(pageController)
        pageViewContainer.addSubview(pageController.view)
        pageController.view.frame = pageViewContainer.bounds
        pageController.setViewControllers([controllers[0]], direction: .forward, animated: false)
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        segmentControl.underlinePosition()
        if segmentControl.selectedSegmentIndex == 0 {
            pageController.setViewControllers([controllers[0]], direction: .reverse, animated: true)
        } else {
            pageController.setViewControllers([controllers[segmentControl.selectedSegmentIndex]], direction: .forward, animated: true)
        }
    }
    
    @IBAction func confirmTapped(sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.onConfirmed?(self.settingObject)
        }
    }
    
    @IBAction func cancelTapped(sender: UIButton) {
        dismiss(animated: true) { [weak self] in
            self?.onCancelled?()
        }
    }
    
    func removeSwipeGesture() {
        for view in self.pageController.view.subviews {
            if let subView = view as? UIScrollView {
                subView.isScrollEnabled = false
            }
        }
    }
    
    
}

extension TransactionSettingPopup: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
      if let index = controllers.firstIndex(of: viewController) {
        if index < controllers.count - 1 {
          return controllers[index + 1]
        } else {
          return nil
        }
      }
      return nil
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
      if let index = controllers.firstIndex(of: viewController) {
        if index > 0 {
          return controllers[index - 1]
        } else {
          return nil
        }
      }
      return nil
    }
    
}

extension TransactionSettingPopup {
    
    public static func show(on viewController: UIViewController,
                            chain: ChainType,
                            currentSetting: TxSettingObject = .default,
                            onConfirmed: @escaping (TxSettingObject) -> Void,
                            onCancelled: @escaping (() -> Void) = {}) {
        let popup = TransactionSettingPopup.instantiateFromNib()
        popup.onCancelled = onCancelled
        popup.onConfirmed = onConfirmed
        popup.chain = chain
        popup.settingObject = currentSetting
        let options = SheetOptions(pullBarHeight: 0)
        let sheet = SheetViewController(controller: popup, sizes: [.percent(0.8)], options: options)
        viewController.present(sheet, animated: true)
    }
    
}
