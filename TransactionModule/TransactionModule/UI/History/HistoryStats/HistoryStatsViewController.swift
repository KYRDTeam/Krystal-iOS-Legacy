//
//  HistoryStatsViewController.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 04/01/2023.
//

import UIKit
import Utilities
import SkeletonView
import DesignSystem

public class HistoryStatsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    public var viewModel: HistoryStatsViewModel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        bindViewModel()
        showSkeletonLoading()
        viewModel.getTxStats()
    }
    
    func bindViewModel() {
        viewModel.onTxStatsUpdated = { [weak self] in
            self?.hideSkeletonLoading()
            self?.tableView.reloadData()
        }
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCellNib(HistoryStatsCell.self)
    }
    
    func showSkeletonLoading() {
        let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    func hideSkeletonLoading() {
        view.hideSkeleton()
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        parent?.dismiss(animated: true)
    }
    
}

extension HistoryStatsViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellTypes.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(HistoryStatsCell.self, indexPath: indexPath)!
        cell.configure(type: viewModel.cellTypes[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
    
}

extension HistoryStatsViewController: SkeletonTableViewDataSource {
    
    public func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    public func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return HistoryStatsCell.className
    }
    
}
