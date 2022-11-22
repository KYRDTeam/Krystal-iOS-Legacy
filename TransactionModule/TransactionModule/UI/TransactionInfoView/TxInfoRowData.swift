//
//  TransactionInfoRowData.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 08/11/2022.
//

import Foundation

public struct TxInfoRowData {
    public var title: String
    public var value: String
    public var isHighlighted: Bool
    public var isTitleUnderlined: Bool
    public var rightButtonTitle: String?
    public var rightButtonClick: (() -> ())?
    public var onTitleClick: () -> ()
    public var onValueClick: () -> ()
    
    public init(title: String, value: String, isHighlighted: Bool = false, isTitleUnderlined: Bool = false, rightButtonTitle: String? = nil, rightButtonClick: @escaping (() -> ()) = {}, onTitleClick: @escaping () -> () = {}, onValueClick: @escaping () -> () = {}) {
        self.title = title
        self.value = value
        self.isHighlighted = isHighlighted
        self.isTitleUnderlined = isTitleUnderlined
        self.rightButtonTitle = rightButtonTitle
        self.rightButtonClick = rightButtonClick
        self.onTitleClick = onTitleClick
        self.onValueClick = onValueClick
    }
}
