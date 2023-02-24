//
//  TokenSearchViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 02/08/2022.
//

import UIKit
import SkeletonView
import BaseModule
import Dependencies
import Services
import Utilities
import DesignSystem
import ChainModule

public class TokenSearchV2ViewController: KNBaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var searchFieldActionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var searchViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var tableViewTopConstraintToSearchView: NSLayoutConstraint!
    @IBOutlet weak var separator: UIView!
    
    public var onSelectToken: ((ChainModule.Token) -> Void)?
    let collectionViewLeftPadding = 21.0
    let collectionViewCellPadding = 12.0
    let collectionViewCellWidth = 86.0
    var defaultCommonTokensInOneRow: CGFloat {
        return UIScreen.main.bounds.size.width - collectionViewLeftPadding * 2 >= collectionViewCellWidth * 4 + collectionViewCellPadding * 3 ? 4 : 3
    }
    var viewModel: TokenSearchV2ViewModel!
    var timer: Timer?
    var isSourceToken: Bool = true
    
    var orderBy: String {
        return self.isSourceToken ? "usdValue" : "tag"
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        AppDependencies.tracker.track("search_open", properties: ["screenid": "search"])
        
        if viewModel.isSearchApiSupported {
            tableViewTopConstraintToSearchView.constant = 124
            view.layoutIfNeeded()
            viewModel.fetchCommonBaseTokens {
                self.collectionView.reloadData()
            }
        } else {
            tableViewTopConstraintToSearchView.constant = 11
            view.layoutIfNeeded()
            collectionView.isHidden = true
            separator.isHidden = true
        }
        
        search(query: "")
    }
    
    func setupUI() {
        self.view.isUserInteractionDisabledWhenSkeletonIsActive = false
        self.searchField.setPlaceholder(text: String.findTokenByNameSymbolAddress, color: AppTheme.current.secondaryTextColor)
        self.tableView.delegate = self
        self.tableView.registerCellNib(SearchTokenViewCell.self)
        self.tableView.registerCellNib(OverviewSkeletonCell.self)
        self.tableView.tableHeaderView = .init(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        self.tableView.sectionHeaderHeight = 0
        self.collectionView.registerCellNib(CommonBaseTokenCell.self)
        self.collectionViewHeight.constant = 40 * 2 + 16
    }
    
    func reloadUI() {
        self.emptyView.isHidden = !self.viewModel.items.isEmpty
        self.tableView.reloadData()
    }
    
    func updateUIStartSearchingMode() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.searchViewRightConstraint.constant = 77
            self.topViewHeight.constant = 0
            self.topView.isHidden = true
            self.cancelButton.isHidden = false
            self.searchFieldActionButton.setImage(Images.closeSearchIcon, for: .normal)
            self.view.layoutIfNeeded()
        }
    }
    
    func updateUIEndSearchingMode() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.searchViewRightConstraint.constant = 21
            self.topViewHeight.constant = 90
            self.topView.isHidden = false
            self.cancelButton.isHidden = true
            self.searchFieldActionButton.setImage(Images.searchIcon, for: .normal)
            self.view.endEditing(true)
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onSearchButtonTapped(_ sender: Any) {
        if self.topView.isHidden {
            searchField.text = ""
            search(query: "")
        } else {
            self.updateUIStartSearchingMode()
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.updateUIEndSearchingMode()
    }
    
    func search(query: String) {
        self.showLoading()
        self.viewModel.search(query: query) {
            self.hideLoading()
            self.reloadUI()
        }
    }
}

extension TokenSearchV2ViewController: UITextFieldDelegate {
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.updateUIStartSearchingMode()
        return true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.updateUIEndSearchingMode()
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        search(query: text)
        return true
    }
}

extension TokenSearchV2ViewController {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(SearchTokenViewCell.self, indexPath: indexPath)!
        cell.configure(item: viewModel.items[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }
}

extension TokenSearchV2ViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let token = viewModel.items[indexPath.row].token
        TokenDB.shared.save(token: token)
        dismiss(animated: true) {
            self.onSelectToken?(token)
        }
    }
}

extension TokenSearchV2ViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.commonBaseTokens.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(CommonBaseTokenCell.self, indexPath: indexPath)!
        let token = self.viewModel.commonBaseTokens[indexPath.row]
        cell.updateUI(token: token)
        return cell
    }
}

extension TokenSearchV2ViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let commonBaseToken = self.viewModel.commonBaseTokens[indexPath.row]
        let token = ChainModule.Token(chainID: viewModel.chainID, address: commonBaseToken.address, iconUrl: commonBaseToken.logo, decimal: commonBaseToken.decimals, symbol: commonBaseToken.symbol, name: commonBaseToken.name, tag: commonBaseToken.tag ?? "", type: "erc20", isAddedByUser: false)
        TokenDB.shared.save(token: token)
        dismiss(animated: true) {
            self.onSelectToken?(token)
        }
    }
}

extension TokenSearchV2ViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let token = self.viewModel.commonBaseTokens[indexPath.row]
        let symbolWidth = token.symbol.width(withConstrainedHeight: 18, font: UIFont.karlaReguler(ofSize: 14))
        
        return CGSize(width: symbolWidth + 50, height: 36)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var contentSize = 0.0
        if self.viewModel.commonBaseTokens.count >= Int(defaultCommonTokensInOneRow) {
            for index in 0..<Int(defaultCommonTokensInOneRow) {
                let token = self.viewModel.commonBaseTokens[index]
                let symbolWidth =  token.symbol.width(withConstrainedHeight: 18, font: UIFont.karlaReguler(ofSize: 14))
                contentSize += (symbolWidth + 50)
            }
        } else {
            contentSize =  defaultCommonTokensInOneRow * collectionViewCellWidth
        }
        
        let rightPadding = UIScreen.main.bounds.size.width - (collectionViewLeftPadding + contentSize + (defaultCommonTokensInOneRow - 1) * collectionViewCellPadding)
        return UIEdgeInsets(top: 8, left: collectionViewLeftPadding, bottom: 8, right: rightPadding)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionViewCellPadding
    }
}

extension TokenSearchV2ViewController: SkeletonTableViewDelegate, SkeletonTableViewDataSource {
    
    func showLoading() {
        let gradient = SkeletonGradient(baseColor: AppTheme.current.sectionBackgroundColor)
        view.showAnimatedGradientSkeleton(usingGradient: gradient)
    }
    
    func hideLoading() {
        view.hideSkeleton()
    }
    
    public func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    public func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = skeletonView.dequeueReusableCell(OverviewSkeletonCell.self, indexPath: indexPath)!
        return cell
    }
    
    public func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return OverviewSkeletonCell.className
    }
    
}
