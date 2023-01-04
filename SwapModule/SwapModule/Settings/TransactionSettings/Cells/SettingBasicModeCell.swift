//
//  SettingBasicModeCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/08/2022.
//

import UIKit
import BigInt
import Services
import DesignSystem
import Dependencies

class SettingBasicModeCellModel {
    fileprivate(set) var fast: BigInt = AppDependencies.gasConfig.currentChainFastGasPrice
    fileprivate(set) var medium: BigInt = AppDependencies.gasConfig.currentChainStandardGasPrice
    fileprivate(set) var slow: BigInt = AppDependencies.gasConfig.currentChainLowGasPrice
    var gasLimit: BigInt = .zero
    var selectedIndex = 2
    var actionHandler: (Int) -> Void = { _ in }
    var rate: Rate?
    var quoteToken: TokenDetailInfo? {
        didSet {
            self.onQuoteTokenUpdated?()
        }
    }
    
    var onQuoteTokenUpdated: (() -> ())? = nil
    
    func updateQuoteToken(quoteToken: TokenDetailInfo?) {
        self.quoteToken = quoteToken
    }
    
    func resetData() {
        fast = AppDependencies.gasConfig.currentChainFastGasPrice
        medium = AppDependencies.gasConfig.currentChainStandardGasPrice
        slow = AppDependencies.gasConfig.currentChainLowGasPrice
        selectedIndex = 2
    }
}


class SettingBasicModeCell: UITableViewCell {
    @IBOutlet weak var fastContainerView: UIView!
    @IBOutlet weak var standardContainerView: UIView!
    @IBOutlet weak var slowContainerView: UIView!
    @IBOutlet var optionViews: [UIView]!
    
    var cellModel: SettingBasicModeCellModel! {
        didSet {
            cellModel?.onQuoteTokenUpdated = { [weak self] in
                self?.updateUI()
            }
        }
    }
    
    var quoteTokenPrice: Double? {
        return cellModel.quoteToken?.markets["usd"]?.price
    }
    
    func updateUI() {
        self.optionViews.forEach { item in
            let selected = self.cellModel.selectedIndex == item.tag
            self.updateOptionViewsUI(aView: item, selected: selected, quoteTokenPrice: quoteTokenPrice)
        }
    }
    
    @IBAction func optionButtonTapped(_ sender: UIButton) {
        let tag = sender.tag
        self.cellModel.selectedIndex = tag
        self.updateUI()
        cellModel.actionHandler(tag)
    }
    
    func updateOptionViewsUI(aView: UIView, selected: Bool, quoteTokenPrice: Double?) {
        aView.rounded(color: selected ? AppTheme.current.primaryColor : AppTheme.current.primaryTextColor, width: 1, radius: 14)
        if let priceView = aView.viewWithTag(9) as? UILabel {
            priceView.textColor = selected ?  AppTheme.current.primaryColor : AppTheme.current.primaryTextColor
            switch aView.tag {
            case 3:
                priceView.text = cellModel.fast.formatFeeString(type: 3, rate: cellModel.rate, quoteTokenPrice: quoteTokenPrice)
            case 2:
                priceView.text = cellModel.medium.formatFeeString(type: 2, rate: cellModel.rate, quoteTokenPrice: quoteTokenPrice)
            case 1:
                priceView.text = cellModel.slow.formatFeeString(type: 1, rate: cellModel.rate, quoteTokenPrice: quoteTokenPrice)
            default:
                break
            }
        }
        if let gweiValue = aView.viewWithTag(10) as? UILabel {
            switch aView.tag {
            case 3:
                gweiValue.text = cellModel.fast.displayGWEI()
            case 2:
                gweiValue.text = cellModel.medium.displayGWEI()
            case 1:
                gweiValue.text = cellModel.slow.displayGWEI()
            default:
                break
            }
        }
    }
}
