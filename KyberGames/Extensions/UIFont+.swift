//
//  UIFont+.swift
//  KyberGames
//
//  Created by Nguyen Tung on 06/04/2022.
//

import UIKit

extension UIFont {
  
  static func registerFont(withFilenameString filenameString: String, bundle: Bundle) {
    guard let pathForResourceString = bundle.path(forResource: filenameString, ofType: nil) else {
      print("UIFont+:  Failed to register font - path for resource not found.")
      return
    }
    
    guard let fontData = NSData(contentsOfFile: pathForResourceString) else {
      print("UIFont+:  Failed to register font - font data could not be loaded.")
      return
    }
    
    guard let dataProvider = CGDataProvider(data: fontData) else {
      print("UIFont+:  Failed to register font - data provider could not be loaded.")
      return
    }
    
    guard let font = CGFont(dataProvider) else {
      print("UIFont+:  Failed to register font - font could not be loaded.")
      return
    }
    
    var errorRef: Unmanaged<CFError>? = nil
    if (CTFontManagerRegisterGraphicsFont(font, &errorRef) == false) {
      print("UIFont+:  Failed to register font - register graphics font failed - this font may have already been registered in the main bundle.")
    }
  }
  
  static func registerFonts() {
    registerFont(withFilenameString: "Coiny-Regular.ttf",
                 bundle: Bundle(for: KyberGamesModule.self))
  }
  
  static func coinyFont(ofSize size: CGFloat) -> UIFont {
    return UIFont(name: "Coiny-Regular", size: size)!
  }
  
}
