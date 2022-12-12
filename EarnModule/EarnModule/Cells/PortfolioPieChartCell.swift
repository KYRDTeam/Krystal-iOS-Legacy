//
//  PortfolioPieChartCell.swift
//  EarnModule
//
//  Created by Com1 on 06/12/2022.
//

import UIKit
import Charts
import DesignSystem

class PortfolioPieChartCell: UITableViewCell {
    @IBOutlet weak var dailyEarningLabel: UILabel!
    @IBOutlet weak var annualYieldLabel: UILabel!
    @IBOutlet weak var apyValueLabel: UILabel!
    @IBOutlet weak var totalUSDValueLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pieChartView: PieChartView!

    var currentSelectedIndex: Int?
    var viewModel: PortfolioPieChartCellViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerCellNib(ChartLegendTokenCell.self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateUI() {
        guard let viewModel = viewModel else { return }
        loadChartView()
        totalUSDValueLabel.text = viewModel.earningAssetsString
        apyValueLabel.text = viewModel.apyString
        annualYieldLabel.text = viewModel.annualYieldString
        dailyEarningLabel.text = viewModel.dailyEarningString
        collectionView.reloadData()
    }
    
    func loadChartView() {
        pieChartView.delegate = self
        pieChartView.legend.enabled = false
        pieChartView.holeColor = AppTheme.current.sectionBackgroundColor
        pieChartView.holeRadiusPercent = 0.65
        self.setChartData()
    }
    
    func setChartData() {
        guard let viewModel = viewModel else { return }
        var entries: [PieChartDataEntry] = []
        var chartColors: [UIColor] = []
        if viewModel.dataSource.count > 5 {
            chartColors = AppTheme.current.chartColors.prefix(5) + [AppTheme.current.chartColors.last!]
            for index in 0..<5 {
                let earningBalance = viewModel.dataSource[index]
                let chartEntry = PieChartDataEntry(value: earningBalance.usdValue())
                entries.append(chartEntry)
            }
            let otherPiechartEntry = PieChartDataEntry(value: viewModel.remainUSDValue ?? 0)
            entries.append(otherPiechartEntry)
        } else {
            chartColors = AppTheme.current.chartColors
            for index in 0..<viewModel.dataSource.count {
                let earningBalance = viewModel.dataSource[index]
                let chartEntry = PieChartDataEntry(value: earningBalance.usdValue())
                entries.append(chartEntry)
            }
        }
        let set = PieChartDataSet(entries: entries)
        set.drawIconsEnabled = false
        set.drawValuesEnabled = false
        set.selectionShift = 10
        set.colors = chartColors
        
        let data = PieChartData(dataSet: set)
        pieChartView.data = data
        pieChartView.animate(xAxisDuration: 0.8)
    }
    
}

extension PortfolioPieChartCell: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        if self.currentSelectedIndex == Int(highlight.x) {
            self.currentSelectedIndex = nil
            pieChartView.highlightValue(nil)
        } else {
            self.currentSelectedIndex = Int(highlight.x)
        }
        
        self.collectionView.reloadData()
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        self.currentSelectedIndex = nil
        self.collectionView.reloadData()
    }
}


extension PortfolioPieChartCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let viewModel = viewModel else { return 0 }
        return viewModel.dataSource.count > 5 ? 6 : viewModel.dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ChartLegendTokenCell.self, indexPath: indexPath)!
        if let currentSelectedIndex = currentSelectedIndex, currentSelectedIndex == indexPath.row {
            cell.containtView.backgroundColor = AppTheme.current.primaryColor.withAlphaComponent(0.4)
        } else {
            cell.containtView.backgroundColor = .clear
        }
        if let viewModel = viewModel {
            if indexPath.row == 5 {
                cell.updateUILastCell(totalValue: viewModel.earningAssets, remainValue: viewModel.remainUSDValue)
            } else {
                cell.updateUI(earningBalance: viewModel.dataSource[indexPath.row], totalValue: viewModel.earningAssets, index: indexPath.row )
            }
        }
        return cell
    }
}

extension PortfolioPieChartCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pieChartView.highlightValue(x: Double(indexPath.row), dataSetIndex: 0)
    }
}

extension PortfolioPieChartCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
      return UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return ChartLegendTokenCell.legendSize
    }
}
