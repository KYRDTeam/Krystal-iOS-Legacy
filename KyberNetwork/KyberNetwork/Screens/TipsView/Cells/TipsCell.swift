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
    @IBOutlet weak var containerView: UIView!

    var contentHeight: CGFloat {
        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = containerView.frame.width - 32
        return systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow).height
    }
    
    func updateUIExpanse(isExpand: Bool) {
        detailTipsLabel.isHidden = !isExpand
        updateIcon(isExpand: isExpand)
        var rect = self.frame
        rect.size.height = isExpand ? contentHeight : 80
        self.frame = rect
    }
    
    func updateIcon(isExpand: Bool) {
        dropDownIcon.transform = isExpand ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat(Double.pi))
    }
}
