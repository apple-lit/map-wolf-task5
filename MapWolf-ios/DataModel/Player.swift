//
//  Player.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseFirestore
import Foundation

enum PlayerRole: String, Codable {
    case crewmate
    case impostor
    case unknown

    var iconText: String {
        switch self {
        case .impostor:
            return "🦹"
        case .crewmate:
            return "👨‍🚀"
        default:
            return ""
        }
    }

    var name: String {
        switch self {
        case .impostor:
            return "Impostor"
        case .crewmate:
            return "Crewmate"
        default:
            return ""
        }
    }
}

struct PlayerLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    static let zero: PlayerLocation = .init(latitude: 0, longitude: 0)
}

protocol Player: FirestoreModel, SubCollectionModel {
    var ref: DocumentReference? { get }
    var uid: String? { get }
    var nickName: String { get }
    var qrCode: String { get }
    var role: PlayerRole { get }
    var color: PlayerColor { get }
    var avatar: Avatar { get }
    var location: PlayerLocation? { get set }
}
