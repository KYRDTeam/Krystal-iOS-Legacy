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

    @IBOutlet weak var pieChartView: PieChartView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func loadChartData() {
        pieChartView.delegate = self
        pieChartView.legend.enabled = false
        pieChartView.holeColor = AppTheme.current.sectionBackgroundColor
        pieChartView.holeRadiusPercent = 0.7
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
    
}
