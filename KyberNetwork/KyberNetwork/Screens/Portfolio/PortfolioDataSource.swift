//
//  PortfolioDataSource.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 11/07/2022.
//

import Foundation
import RxDataSources

struct PortfolioDataSource {
  typealias DataSource = RxTableViewSectionedReloadDataSource
  
  static func dataSource() -> DataSource<PortfolioSectionModel> {
    return .init(configureCell: { dataSource, tableView, indexPath, item -> UITableViewCell in
      switch dataSource[indexPath] {
      case .asset(let token):
        let viewModel = PortfolioAssetCellViewModel(token: token, currencyMode: .usd, hideBalance: false)
        let cell = tableView.dequeueReusableCell(PortfolioAssetCell.self, indexPath: indexPath)!
        cell.configure(viewModel: viewModel)
        return cell
      default:
        return UITableViewCell()
      }
    }, titleForHeaderInSection: { dataSource, index in
      return nil
    })
  }
}
