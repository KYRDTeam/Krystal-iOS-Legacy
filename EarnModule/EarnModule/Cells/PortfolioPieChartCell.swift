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
        loadChartData()
        totalUSDValueLabel.text = viewModel.earningAssetsString
        apyValueLabel.text = viewModel.apyString
        annualYieldLabel.text = viewModel.annualYieldString
        dailyEarningLabel.text = viewModel.dailyEarningString
    }
    
    func loadChartData() {
        pieChartView.delegate = self
        pieChartView.legend.enabled = false
        pieChartView.holeColor = AppTheme.current.sectionBackgroundColor
        pieChartView.holeRadiusPercent = 0.65
        self.setDataCount(Int(6), range: UInt32(6))
    }
    
    func setDataCount(_ count: Int, range: UInt32) {
        let entries = (0..<count).map { (i) -> PieChartDataEntry in
            // IMPORTANT: In a PieChart, no values (Entry) should have the same xIndex (even if from different DataSets), since no values can be drawn above each other.
            return PieChartDataEntry(value: Double(arc4random_uniform(range) + range / 5))
        }
        
        let set = PieChartDataSet(entries: entries, label: "Election Results")
        set.drawIconsEnabled = false
        set.drawValuesEnabled = false
        set.selectionShift = 10
        
        set.colors = ChartColorTemplates.vordiplom()
            + ChartColorTemplates.joyful()
            + ChartColorTemplates.colorful()
            + ChartColorTemplates.liberty()
            + ChartColorTemplates.pastel()
            + [UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)]
        
        let data = PieChartData(dataSet: set)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        
        data.setValueFont(.systemFont(ofSize: 11, weight: .light))
        data.setValueTextColor(.black)
        
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
        return 6
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
