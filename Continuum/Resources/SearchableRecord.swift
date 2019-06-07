//
//  SearchableRecord.swift
//  Continuum
//
//  Created by Lo on 6/4/19.
//  Copyright © 2019 Lo Howard. All rights reserved.
//

import Foundation

protocol SearchableRecord {
  func matches(searchTerm: String) -> Bool
}
