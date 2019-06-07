//
//  UIViewControllerExtension.swift
//  Continuum
//
//    Created by Lo on 6/4/19.
//  Copyright © 2019 Lo Howard. All rights reserved.
//

import UIKit

extension UIViewController {
  func presentSimpleAlertWith(title: String, message: String?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
    alertController.addAction(okayAction)
    present(alertController, animated: true)
  }
}
