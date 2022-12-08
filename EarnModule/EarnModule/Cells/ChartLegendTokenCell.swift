//
//  ChartLegendTokenCell.swift
//  EarnModule
//
//  Created by Com1 on 07/12/2022.
//

import UIKit

class ChartLegendTokenCell: UICollectionViewCell {
    static let legendSize: CGSize = CGSize(width: 156, height: 35)
    
    @IBOutlet weak var legendColorView: UIView!
    @IBOutlet weak var tokenImageView: UIImageView!
    @IBOutlet weak var chainImageView: UIImageView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBOutlet weak var containtView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
