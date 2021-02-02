//
//  ResultViewModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/31.
//

import Combine
import RxRelay
import RxSwift
import SwiftUI

class ResultViewModel: ObservableObject {
    // "VICTORY" or "DEFEATED"
    @Published var resultMessage: String = ""
    @Published var winnerRole: PlayerRole
    @Published var myRole: PlayerRole = .unknown
    @Published var winners: [ResultUser] = []
    @Published var losers: [ResultUser] = []

    private let model: ResultModelType
    private let disposeBag = DisposeBag()

    init(winnerRole: PlayerRole) {
        self.winnerRole = winnerRole
        self.model = ResultModel(winnerRole: winnerRole)

        model.losers.subscribe(onNext: { [weak self] losers in
            self?.losers = losers.map({
                ResultUser(id: $0.uid ?? "", avatarEmoji: $0.avatar.resourceName)
            })
        }).disposed(by: disposeBag)

        model.winners.subscribe(onNext: { [weak self] winners in
            self?.winners = winners.map({
                ResultUser(id: $0.uid ?? "", avatarEmoji: $0.avatar.resourceName)
            })
        }).disposed(by: disposeBag)

        model.myRole.subscribe(onNext: { [weak self] myRole in
            guard let self = self else {
                return
            }
            self.myRole = myRole
            if myRole == winnerRole {
                self.resultMessage = "VICTORY"
            } else {
                self.resultMessage = "DEFEATED"
            }
        }).disposed(by: disposeBag)
    }
}
