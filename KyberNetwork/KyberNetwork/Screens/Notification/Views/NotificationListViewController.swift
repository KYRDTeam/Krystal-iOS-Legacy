//
//  NotificationListViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import UIKit
import SkeletonView

protocol NotificationListViewControllerDelegate: AnyObject {
  func onSelectNotification(id: Int)
}

class NotificationListViewController: UIViewController {
  @IBOutlet weak var emptyView: ListEmptyView!
  @IBOutlet weak var tableView: UITableView!
  private let refreshControl = UIRefreshControl()
  
  var viewModel: NotificationListViewModel!
  weak var delegate: NotificationListViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
    setupRefreshControl()
    showLoadingSkeleton()
    loadData()
  }
  
  func showLoadingSkeleton() {
    let gradient = SkeletonGradient(baseColor: UIColor.Kyber.cellBackground)
    view.showAnimatedGradientSkeleton(usingGradient: gradient)
  }
  
  func setupRefreshControl() {
    refreshControl.tintColor = UIColor.white.withAlphaComponent(0.5)
  }
  
  func setupTableView() {
    if #available(iOS 10.0, *) {
      tableView.refreshControl = refreshControl
    } else {
      tableView.addSubview(refreshControl)
    }
    refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    tableView.registerCellNib(NotificationItemV2Cell.self)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.estimatedRowHeight = 96
    
  }
  
  @objc func refreshData() {
    self.refreshControl.beginRefreshing()
    self.loadData(reset: true)
  }
  
  func loadData(reset: Bool = false) {
    self.viewModel.load(reset: reset) {
      self.tableView.hideSkeleton()
      self.refreshControl.endRefreshing()
      self.reloadUI()
    }
  }
  
  func reloadUI() {
    DispatchQueue.main.async {
      self.emptyView?.isHidden = !self.viewModel.notifications.isEmpty
      self.tableView?.reloadData()
    }
  }
  
}

extension NotificationListViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.notifications.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(NotificationItemV2Cell.self, indexPath: indexPath)!
    cell.configure(viewModel: viewModel.notifications[indexPath.row])
    cell.selectionStyle = .none
    return cell
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if !viewModel.isLoading && indexPath.item == viewModel.notifications.count - 5 && viewModel.canLoadMore {
      self.loadData(reset: false)
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    delegate?.onSelectNotification(id: viewModel.notifications[indexPath.row].id)
  }
  
  func readNotification(id: Int) {
    if let index = viewModel.notifications.firstIndex(where: { $0.id == id }) {
      if viewModel.statusToFilter == .unread {
        let indexPath = IndexPath(row: index, section: 0)
        viewModel.notifications.remove(at: index)
        tableView.deleteRows(at: [indexPath], with: .right)
        emptyView.isHidden = !self.viewModel.notifications.isEmpty
      } else {
        let indexPath = IndexPath(row: index, section: 0)
        viewModel.read(id: viewModel.notifications[index].id)
        viewModel.notifications[index].isRead = true
        tableView.reloadRows(at: [indexPath], with: .none)
      }
      view.layoutIfNeeded()
    }
  }
  
  func readAll() {
    if viewModel.statusToFilter == .unread {
      viewModel.notifications.removeAll()
    } else {
      viewModel.notifications.forEach { $0.isRead = true }
    }
    reloadUI()
  }
  
}

extension NotificationListViewController: SkeletonTableViewDataSource {
  
  func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
    return NotificationItemV2Cell.className
  }
  
  func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
  
}
