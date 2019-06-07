//
//  Comment.swift
//  Continuum
//
//  Created by Lo on 6/4/19.
//  Copyright © 2019 Lo Howard. All rights reserved.
//

import Foundation
import CloudKit

class Comment {
  let text: String
  let timestamp: Date
  weak var post: Post?
  let recordID: CKRecord.ID
  
  var postReference: CKRecord.Reference? {
    guard let post = post else { return nil }
    return CKRecord.Reference(recordID: post.recordID, action: .deleteSelf)
  }
  
  init(text: String, post: Post, timestamp: Date = Date(), recordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString)) {
    self.text = text
    self.post = post
    self.timestamp = timestamp
    self.recordID = recordID
  }
  
  convenience init?(ckRecord: CKRecord, post: Post){
    guard let text = ckRecord[CommentConstants.textKey] as? String,
      let timestamp = ckRecord[CommentConstants.timestampKey] as? Date else { return nil }
    self.init(text: text, post: post, timestamp: timestamp, recordID: ckRecord.recordID)
  }
}

extension Comment: SearchableRecord {
  func matches(searchTerm: String) -> Bool {
    return text.contains(searchTerm)
  }
}

struct CommentConstants {
  static let recordType = "Comment"
  static let textKey = "text"
  static let timestampKey = "timestamp"
  static let postReferenceKey = "post"
}
