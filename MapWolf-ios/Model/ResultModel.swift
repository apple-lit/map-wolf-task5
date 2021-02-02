//
//  ResultModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/27.
//

import Foundation
import RxRelay
import RxSwift

protocol ResultModelType {
    var winners: Observable<[Player]> { get }
    var losers: Observable<[Player]> { get }
    var myRole: Observable<PlayerRole> { get }
}

class ResultModel: ResultModelType {
    let store: Store = .shared
    let winnerRole: PlayerRole

    var winners: Observable<[Player]> {
        if winnerRole == .crewmate {
            return store.crewmates.asObservable().map({ $0.map({ $0 as Player }) })
        } else if winnerRole == .impostor {
            return store.impostors.asObservable().map({ $0.map({ $0 as Player }) })
        }
        return .empty()
    }

    var myRole: Observable<PlayerRole> {
        store.me.compactMap({ $0?.role })
    }

    var losers: Observable<[Player]> {
        if winnerRole == .crewmate {
            return store.impostors.asObservable().map({ $0.map({ $0 as Player }) })
        } else if winnerRole == .impostor {
            return store.crewmates.asObservable().map({ $0.map({ $0 as Player }) })
        }
        return .empty()
    }

    init(winnerRole: PlayerRole) {
        self.winnerRole = winnerRole
    }
}
