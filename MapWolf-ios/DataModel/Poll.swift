//
//  Poll.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Poll: FirestoreModel, SubCollectionModel {
    static var identifier: String = collectionName
    static var parentCollectionName: String = "rooms"
    static var collectionName: String = "polls"
    @DocumentID
    var ref: DocumentReference?

    var triggerPlayer: Candidate?
    var result: [String: [String]]
    var participants: [String]
    var deadPlayer: Candidate?
    var isEmergency: Bool
    var date: Date
    var isSkipped: Bool
    var explicitSkipUserIDList: [String]
}

extension Poll {
    var uid: String? {
        ref?.documentID
    }
}
