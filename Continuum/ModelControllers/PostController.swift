//
//  PostController.swift
//  Continuum
//
//  Created by Lo on 6/4/19.
//  Copyright © 2019 Lo Howard. All rights reserved.
//

import UIKit
import CloudKit

class PostController {
    
    //MARK: - SharedInstance
    static let shared = PostController()
    private init() {
        subscribeToNewPosts(completion: nil)
    }
    
    //MARK: - Source of Truth
    var posts: [Post] = []
    
    //MARK: - CRUD Methods
    //MARK: - Create Methods
    func addComment(text: String, post: Post, completion: @escaping (Comment?) -> Void) {
        let comment = Comment(text: text, post: post)
        post.comments.append(comment)
        let record = CKRecord(comment: comment)
        CKContainer.default().publicCloudDatabase.save(record) { (record, error) in
            if let error = error{
                print("\(error.localizedDescription) \(error) in function: \(#function)")
                completion(nil)
                return
            }
            
            guard let record = record else { completion(nil) ; return }
            let comment = Comment(ckRecord: record, post: post)
            self.incrementCommentCount(for: post, completion: nil)
            completion(comment)
        }
    }
    
    func createPostWith(photo: UIImage, caption: String, completion: @escaping (Post?) -> Void) {
        let post = Post(photo: photo, caption: caption)
        self.posts.append(post)
        let record = CKRecord(post: post)
        CKContainer.default().publicCloudDatabase.save(record) { (record, error) in
            if let error = error{
                print("\(error.localizedDescription) \(error) in function: \(#function)")
                completion(nil)
                return
            }
            
            guard let record = record,
                let post = Post(ckRecord: record)  else { completion(nil) ; return }
            completion(post)
        }
    }
    
    //MARK: - Read Methods
    func fetchPosts(completion: @escaping ([Post]?) -> Void){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PostConstants.typeKey, predicate: predicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error{
                print("\(error.localizedDescription) \(error) in function: \(#function)")
                completion(nil)
                return
            }
            guard let records = records else { completion(nil) ; return }
            let posts = records.compactMap{ Post(ckRecord: $0) }
            self.posts = posts
            completion(posts)
        }
    }
    
    func fetchComments(for post: Post, completion: @escaping ([Comment]?) -> Void){
        let postRefence = post.recordID
        
        let predicate = NSPredicate(format: "%K == %@", CommentConstants.postReferenceKey, postRefence)
        let commentIDs = post.comments.compactMap({$0.recordID})
        
        let predicate2 = NSPredicate(format: "NOT(recordID IN %@)", commentIDs)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
        let query = CKQuery(recordType: "Comment", predicate: compoundPredicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error fetching comments from cloudKit \(#function) \(error) \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let records = records else { completion(nil); return }
            let comments = records.compactMap{ Comment(ckRecord: $0, post: post) }
            post.comments.append(contentsOf: comments)
            completion(comments)
        }
    }
    
    //MARK: - Update Methods
    func incrementCommentCount(for post: Post, completion: ((Bool)-> Void)?){
        post.commentCount += 1
        let modifyOperation = CKModifyRecordsOperation(recordsToSave: [CKRecord(post: post)], recordIDsToDelete: nil)
        modifyOperation.savePolicy = .changedKeys
        modifyOperation.modifyRecordsCompletionBlock = { (records, _, error) in
            if let error = error{
                print("\(error.localizedDescription) \(error) in function: \(#function)")
                completion?(false)
                return
            }else {
                completion?(true)
            }
        }
        CKContainer.default().publicCloudDatabase.add(modifyOperation)
    }
    
    //MARK: - CloudKit Subscriptions
    func subscribeToNewPosts(completion: ((Bool, Error?) -> Void)?){
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Post", predicate: predicate, subscriptionID: "AllPosts", options: CKQuerySubscription.Options.firesOnRecordCreation)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New post added to Continuum"
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        CKContainer.default().publicCloudDatabase.save(subscription) { (subscription, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion?(false, error)
            } else {
                completion?(true, nil)
            }
        }
    }
    
    func addSubscritptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?){
        let postRecordID = post.recordID
        let predicate = NSPredicate(format: "%K = %@", CommentConstants.postReferenceKey, postRecordID)
        let subscription = CKQuerySubscription(recordType: "Comment", predicate: predicate, subscriptionID: post.recordID.recordName, options: CKQuerySubscription.Options.firesOnRecordCreation)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "A new comment was added to the post you follow!"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = nil
        subscription.notificationInfo = notificationInfo
        
        CKContainer.default().publicCloudDatabase.save(subscription) { (_, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion?(false, error)
            } else {
                completion?(true, nil)
            }
        }
    }
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: ((Bool) -> ())?){
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: subscriptionID) { (_, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion?(false)
                return
            } else {
                print("Subscription deleted")
                completion?(true)
            }
            
        }
    }
    
    func checkForSubscription(to post: Post, completion: ((Bool) -> ())?){
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion?(false)
                return
            }
            if subscription != nil{
                completion?(true)
            } else {
                completion?(false)
            }
            
        }
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post, completion: ((Bool, Error?) -> ())?){
        checkForSubscription(to: post) { (isSubscribed) in
            if isSubscribed{
                self.removeSubscriptionTo(commentsForPost: post, completion: { (success) in
                    if success{
                        print("Successfully removed the subscription to the post with caption: \(post.caption)")
                        completion?(true, nil)
                    }else{
                        print("Whoops somthing went wrong removing the subscription to the post with caption: \(post.caption)")
                        completion?(false, nil)
                    }
                })
            } else {
                self.addSubscritptionTo(commentsForPost: post, completion: { (success, error) in
                    if let error = error {
                        print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                        completion?(false, error)
                        return
                    }
                    
                    if success{
                        print("Successfully added the subscription to the post with caption: \(post.caption)")
                        completion?(true, nil)
                    } else{
                        print("Whoops somthing went wrong adding the subscription to the post with caption: \(post.caption)")
                        completion?(false, nil)
                    }
                })
            }
        }
    }
}
