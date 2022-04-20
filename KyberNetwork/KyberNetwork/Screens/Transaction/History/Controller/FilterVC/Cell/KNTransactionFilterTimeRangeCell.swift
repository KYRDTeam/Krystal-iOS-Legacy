//
//  KNTransactionFilterTimeRangeCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 19/04/2022.
//

import UIKit

class KNTransactionFilterTimeRangeCell: UICollectionViewCell {
  @IBOutlet weak var startDateField: UITextField!
  @IBOutlet weak var endDateField: UITextField!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    setupDateFields()
  }
  
  func setupDateFields() {
    self.startDateField.rounded(radius: 16)
    self.endDateField.rounded(radius: 16)

    self.startDateField.attributedPlaceholder = NSAttributedString(
      string: "From",
      attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!]
    )

    self.endDateField.attributedPlaceholder = NSAttributedString(
      string: "To",
      attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!]
    )
  }
  
//  lazy var fromDatePicker: UIDatePicker = {
//    let frame = CGRect(
//      x: 0,
//      y: self.view.frame.height - 200.0,
//      width: self.view.frame.width,
//      height: 200.0
//    )
//    let picker = UIDatePicker(frame: frame)
//    picker.datePickerMode = .date
//    picker.minimumDate = Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
//    picker.maximumDate = Date()
//    picker.addTarget(self, action: #selector(self.fromDatePickerDidChange(_:)), for: .valueChanged)
//    picker.date = Date()
//    if #available(iOS 13.4, *) {
//      picker.preferredDatePickerStyle = .wheels
//    }
//    return picker
//  }()
//
//  lazy var toDatePicker: UIDatePicker = {
//    let frame = CGRect(
//      x: 0,
//      y: self.view.frame.height - 200.0,
//      width: self.view.frame.width,
//      height: 200.0
//    )
//    let picker = UIDatePicker(frame: frame)
//    picker.datePickerMode = .date
//    picker.minimumDate = Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
//    picker.maximumDate = Date()
//    picker.addTarget(self, action: #selector(self.toDatePickerDidChange(_:)), for: .valueChanged)
//    picker.date = Date()
//    if #available(iOS 13.4, *) {
//      picker.preferredDatePickerStyle = .wheels
//    }
//    return picker
//  }()
  
}
