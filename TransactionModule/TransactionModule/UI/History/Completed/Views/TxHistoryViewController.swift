//
//  TxHistoryViewController.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 21/12/2022.
//

import UIKit
import Utilities
import SkeletonView
import DesignSystem

class TxHistoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: TxHistoryViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        bindViewModel()
        viewModel.loadTxHistory(endTime: nil)
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCellNib(TxHeaderCell.self)
        tableView.registerCellNib(TxTokenCell.self)
        tableView.registerCellNib(TxFooterCell.self)
        tableView.registerCellNib(TxSkeletonCell.self)
    }
    
    func bindViewModel() {
        showSkeletonLoading()
        viewModel.onRowsUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.hideSkeletonLoading()
                self?.tableView.reloadData()
            }
        }
    }
    
    func showSkeletonLoading() {
        let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    func hideSkeletonLoading() {
        view.hideSkeleton()
    }
    
}

extension TxHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.rows[indexPath.row]
        switch row {
        case .header(let viewModel):
            let cell = tableView.dequeueReusableCell(TxHeaderCell.self, indexPath: indexPath)!
            cell.configure(viewModel: viewModel)
            cell.selectionStyle = .none
            return cell
        case .tokenChange(let viewModel):
            let cell = tableView.dequeueReusableCell(TxTokenCell.self, indexPath: indexPath)!
            cell.configure(viewModel: viewModel)
            cell.selectionStyle = .none
            return cell
        case .footer(let viewModel):
            let cell = tableView.dequeueReusableCell(TxFooterCell.self, indexPath: indexPath)!
            cell.configure(viewModel: viewModel)
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
    }
    
}


extension TxHistoryViewController: SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return TxSkeletonCell.className
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
}

