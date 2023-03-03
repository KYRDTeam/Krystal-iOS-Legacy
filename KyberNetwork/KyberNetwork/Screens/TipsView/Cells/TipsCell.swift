//
//  TipsCell.swift
//  KyberNetwork
//
//  Created by Com1 on 28/02/2023.
//

import UIKit

class TipsCell: UITableViewCell {
    @IBOutlet weak var dropDownIcon: UIImageView!
    @IBOutlet weak var detailTipsLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var isExpand: Bool = false
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        updateIcon()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateUIExpanse() {
        isExpand.toggle()
        detailTipsLabel.isHidden = !isExpand
        updateIcon()
        var rect = self.frame
        rect.size.height = isExpand ? 120 : 80
        self.frame = rect
    }
    
    func updateIcon() {
        dropDownIcon.transform = isExpand ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat(Double.pi))
    }
}
