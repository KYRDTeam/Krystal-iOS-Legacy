//
//  ImagePicker.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/05/2022.
//

import Foundation
import UIKit

public protocol ImagePickerDelegate: class {
  func didSelect(image: UIImage?)
}

open class ImagePicker: NSObject {
  
  private let pickerController: UIImagePickerController
  private weak var presentationController: UIViewController?
  private weak var delegate: ImagePickerDelegate?
  
  public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
    self.pickerController = UIImagePickerController()
    
    super.init()
    
    self.presentationController = presentationController
    self.delegate = delegate
    
    self.pickerController.delegate = self
    self.pickerController.allowsEditing = true
    self.pickerController.mediaTypes = ["public.image"]
  }
  
  private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
    guard UIImagePickerController.isSourceTypeAvailable(type) else {
      return nil
    }
    
    return UIAlertAction(title: title, style: .default) { [unowned self] _ in
      self.pickerController.sourceType = type
      self.presentationController?.present(self.pickerController, animated: true)
    }
  }
  
  public func present(from sourceView: UIView) {
    self.pickerController.sourceType = .photoLibrary
    self.presentationController?.present(self.pickerController, animated: true)
  }
  
  private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
    controller.dismiss(animated: true, completion: nil)
    
    self.delegate?.didSelect(image: image)
  }
}

extension ImagePicker: UIImagePickerControllerDelegate {
  
  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    self.pickerController(picker, didSelect: nil)
  }
  
  public func imagePickerController(_ picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    guard let image = info[.editedImage] as? UIImage else {
      return self.pickerController(picker, didSelect: nil)
    }
    self.pickerController(picker, didSelect: image)
  }
}

extension ImagePicker: UINavigationControllerDelegate {
  
}
