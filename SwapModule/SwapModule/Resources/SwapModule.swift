//
//  Bundle.swift
//  SwapModule
//
//  Created by Tung Nguyen on 13/10/2022.
//

import Foundation
import UIKit

public class SwapModule {
    static let bundle = Bundle(for: SwapModule.self)
    
    static func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
    
    public static func createSwapCoordinator() -> SwapCoordinator {
        return SwapCoordinator()
    }
}
