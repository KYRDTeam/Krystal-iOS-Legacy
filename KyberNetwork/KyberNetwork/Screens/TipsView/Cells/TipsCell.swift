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
    var isExpand: Bool = false

    var contentHeight: CGFloat {
        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = containerView.frame.width - 32
        return systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow).height
    }
    
    func updateUIExpanse() {
        isExpand.toggle()
        detailTipsLabel.isHidden = !isExpand
        updateIcon()
        var rect = self.frame
        rect.size.height = isExpand ? contentHeight : 80
        self.frame = rect
    }
    
    func updateIcon() {
        dropDownIcon.transform = isExpand ? CGAffineTransform.identity : CGAffineTransform(rotationAngle: CGFloat(Double.pi))
    }
}
