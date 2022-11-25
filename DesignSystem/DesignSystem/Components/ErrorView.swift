//
//  ErrorView.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 24/11/2022.
//

import UIKit
import Utilities

public class ErrorView: BaseXibView {
  public var onGoBackTapped: (() -> ())?
  
  @IBAction func goBackTapped(_ sender: Any) {
    onGoBackTapped?()
  }
}
