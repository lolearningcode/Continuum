//
//  DateExtension.swift
//  Continuum
//
//   Created by Lo on 6/4/19.
//  Copyright © 2019 Lo Howard. All rights reserved.
//

import Foundation

extension Date {
  func stringWith(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter.string(from: self)
  }
}
