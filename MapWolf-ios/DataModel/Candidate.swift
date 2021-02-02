//
//  Candidate.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Candidate: Player {
    static var identifier: String = "candidate"
    static var parentCollectionName: String = "rooms"
    static var collectionName: String = "players"

    @DocumentID
    var ref: DocumentReference?
    var uid: String?
    var qrCode: String
    var nickName: String
    var color: PlayerColor
    var avatar: Avatar
    var role: PlayerRole = .unknown
    var location: PlayerLocation?
}
