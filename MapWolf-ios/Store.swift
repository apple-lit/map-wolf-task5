//
//  Store.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import FirebaseAuth
import RxRelay
import RxSwift
import UIKit

class Store {
    private let firestore: FirestoreClient = .init()
    private let auth: AuthClientType = AuthClient()

    var playerDisposable: Disposable?
    var roomDisposable: Disposable?
    let user: BehaviorRelay<User?> = .init(value: nil)
    let room: BehaviorRelay<Room?> = .init(value: nil)
    let me: BehaviorRelay<Player?> = .init(value: nil)
    let players: BehaviorRelay<[Player]> = .init(value: [])
    let impostors: BehaviorRelay<[Impostor]> = .init(value: [])
    let crewmates: BehaviorRelay<[Crewmate]> = .init(value: [])
    let candidates: BehaviorRelay<[Candidate]> = .init(value: [])
    let polls: BehaviorRelay<[Poll]> = .init(value: [])
    var color: PlayerColor {
        // Default Color
        let defaultColor = PlayerColor.red
        guard let colorHex = UserDefaults.standard.string(forKey: "player_color_hex") else {
            return defaultColor
        }
        return PlayerColor(hex: colorHex)
    }

    var avatar: Avatar {
        // Default Image
        let defaultAvatar = Avatar.defaultAvatar
        guard let resourceName = UserDefaults.standard.string(forKey: "avatar_resource_name") else {
            return defaultAvatar
        }
        return Avatar(resourceName: resourceName)
    }

    private var gameStarted: Bool = false

    static let shared = Store()

    init() {
        listen()

        let gamePlayers = Observable.combineLatest(
            impostors.asObservable(), crewmates.asObservable())

        playerDisposable = Observable.combineLatest(candidates, gamePlayers).map {
            candidates, players -> [Player] in
            if self.gameStarted {
                return players.0 + players.1
            }
            return candidates
        }.bind(to: players)
    }

    func listen() {
        roomDisposable?.dispose()
        var isCalled: Bool = false
        roomDisposable = room.compactMap { $0 }.subscribe(onNext: { [weak self] room in
            guard let roomRef = room.ref, let myUID = self?.auth.uid else {
                return
            }
            if isCalled {
                return
            }
            isCalled = true
            self?.firestore.listen(
                parent: roomRef.documentID, filter: [],
                success: { (players: [Candidate]) in
                    guard let self = self else {
                        return
                    }
                    self.candidates.accept(players)
                    if let me = players.first(where: { $0.uid == myUID }), self.gameStarted == false {
                        self.me.accept(me)
                    }
                },
                failure: { error in
                    assert(false, error.localizedDescription)
                })

            self?.firestore.listen(
                parent: roomRef.documentID, filter: [],
                success: { (players: [Impostor]) in
                    guard let self = self else {
                        return
                    }
                    self.impostors.accept(players)
                },
                failure: { _ in
                })

            self?.firestore.listen(
                parent: roomRef.documentID, filter: [],
                success: { (players: [Crewmate]) in
                    guard let self = self else {
                        return
                    }
                    self.crewmates.accept(players)
                },
                failure: { _ in
                })

            self?.firestore.listen(
                parent: roomRef.documentID, docID: myUID,
                success: { (me: Crewmate) in
                    self?.me.accept(me)
                    self?.gameStarted = true
                },
                failure: { _ in
                })
            self?.firestore.listen(
                parent: roomRef.documentID, docID: myUID,
                success: { (me: Impostor) in
                    self?.me.accept(me)
                    self?.gameStarted = true
                },
                failure: { _ in
                })
            self?.firestore.listen(
                parent: roomRef.documentID, filter: [],
                success: { (polls: [Poll]) in
                    self?.polls.accept(polls)
                },
                failure: { error in
                    assert(false, error.localizedDescription)
                })
            self?.firestore.listen(
                docID: roomRef.documentID,
                success: { (room: Room) in
                    self?.room.accept(room)
                },
                failure: { error in
                    assert(false, error.localizedDescription)
                })
        })
    }
}
