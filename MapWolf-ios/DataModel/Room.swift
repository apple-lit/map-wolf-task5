//
//  Room.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Room: FirestoreModel {
    static var identifier: String = collectionName
    static var collectionName: String = "rooms"

    @DocumentID
    var ref: DocumentReference?

    var searchID: String
    var hostID: String?
    var maximumPlayersCount: Int = 20
    var impostorCount: Int = 1
    var lastPollingStartDate: Date?
    var crewmateTaskProgress: [String: Double]

    var isAllTaskDone: Bool {
        crewmateTaskProgress.allSatisfy({ $0.value >= 1 })
    }
}
