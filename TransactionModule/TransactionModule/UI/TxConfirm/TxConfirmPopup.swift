//
//  TxConfirmViewController.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 08/11/2022.
//

import UIKit
import Loady
import FittedSheets
import Utilities

public class TxConfirmPopup: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chainIconImageView: UIImageView!
    @IBOutlet weak var chainNameLabel: UILabel!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var tokenIconImageView: UIImageView!
    @IBOutlet weak var tokenAmountLabel: UILabel!
    @IBOutlet weak var platformLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var continueButton: LoadyButton!
    
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewToErrorConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewToBottomConstraint: NSLayoutConstraint!

    public var viewModel: TxConfirmViewModelProtocol!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        continueButton.setAnimation(LoadyAnimationType.indicator(with: .init(indicatorViewStyle: .black)))
        
        viewModel.onError = { [weak self] message in
            self?.hideLoading()
            self?.displayError(message: message)
        }
        
        viewModel.onSuccess = { [weak self] in
            self?.hideLoading()
            self?.dismiss(animated: true)
        }
        
        viewModel.onSelectOpenSetting = { [weak self] in
            guard let self = self else { return }
            
            TransactionSettingPopup.show(on: self, chain: .eth) { settingObject in
                self.viewModel.onSettingChanged(settingObject: settingObject)
            }

        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.updateViewConstraints()
        self.tableViewHeight?.constant = self.tableView.contentSize.height
    }
    
    func setupTableView() {
        tableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: 0.1))
        tableView.tableFooterView = .init(frame: .init(x: 0, y: 0, width: 0, height: 0.1))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCellNib(TxInfoCell.self)
    }
    
    func displayError(message: String?) {
        self.messageLabel.text = message
        self.errorView.isHidden = false
        self.tableViewToErrorConstraint.isActive = true
        self.tableViewToBottomConstraint.isActive = false
        self.view.layoutIfNeeded()
        self.sheetViewController?.updateIntrinsicHeight()
        self.sheetViewController?.resize(to: .intrinsic)
    }
    
    func hideError() {
        self.errorView.isHidden = true
        self.tableViewToErrorConstraint.isActive = false
        self.tableViewToBottomConstraint.isActive = true
        self.view.layoutIfNeeded()
        self.sheetViewController?.updateIntrinsicHeight()
        self.sheetViewController?.animateIn(size: .intrinsic, duration: 0.5, completion: nil)
    }
    
    func showLoading() {
        continueButton.startLoading()
    }
    
    func hideLoading() {
        continueButton.stopLoading()
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        if viewModel.isRequesting {
            return
        }
        showLoading()
        viewModel.isRequesting = true
        viewModel.onTapConfirm()
    }
 
    public static func show(onViewController vc: UIViewController, withViewModel viewModel: TxConfirmViewModelProtocol) {
        let popup = TxConfirmPopup.instantiateFromNib()
        popup.viewModel = viewModel
        let sheet = SheetViewController(controller: popup, sizes: [.intrinsic],
                                        options: .init(pullBarHeight: 0))
        vc.present(sheet, animated: true)
    }
    
}

extension TxConfirmPopup: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(TxInfoCell.self, indexPath: indexPath)!
        cell.configure(row: viewModel.rows[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 28
    }
    
}
