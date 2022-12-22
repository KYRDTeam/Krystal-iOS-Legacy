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
    private let refreshControl = UIRefreshControl()
    
    var viewModel: TxHistoryViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        bindViewModel()
        viewModel.load(shouldReset: true)
    }
    
    func setupViews() {
        view.isUserInteractionDisabledWhenSkeletonIsActive = true
        setupTableView()
        setupRefreshControl()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCellNib(TxHeaderCell.self)
        tableView.registerCellNib(TxTokenCell.self)
        tableView.registerCellNib(TxFooterCell.self)
        tableView.registerCellNib(TxSkeletonCell.self)
        tableView.registerCellNib(TxDateCell.self)
        tableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.contentInset = .init(top: 8, left: 0, bottom: 0, right: 0)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    @objc func refreshData() {
        DispatchQueue.main.async {
            self.tableView.beginUpdates()
            self.refreshControl.endRefreshing()
            self.tableView.endUpdates()
        }
        showSkeletonLoading()
        viewModel.load(shouldReset: true)
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
    
    func setupRefreshControl() {
        refreshControl.tintColor = UIColor.white.withAlphaComponent(0.5)
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
        case .date(let date):
            let cell = tableView.dequeueReusableCell(TxDateCell.self, indexPath: indexPath)!
            cell.configure(date: date)
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !viewModel.isLoading && indexPath.item == viewModel.rows.count - 15 && viewModel.canLoadMore {
            self.viewModel.load(shouldReset: false)
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

