//
//  PollingViewModel.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/28.
//

import Combine
import RxRelay
import RxSwift
import SwiftUI

class PollingViewModel: ObservableObject {
    private let disposeBag: DisposeBag = .init()
    private var cancellables: [AnyCancellable] = []
    private let model: PollModelType = PollModel()

    @Published var skipped: Void = ()
    @Published var killedPlayer: PollingUser?
    @Published var selectedUser: PollingUser?
    @Published var allUsers: [PollingUser] = []
    @Published var remainingTime = 0
    @Published var isImpostor: Bool = false
    var currentPoll: Poll?
    private var isPollOrSkipped: Bool = false

    init() {
        model.deadPlayer.subscribe(onNext: { [weak self] deadPlayer, isImpostor in
            guard let uid = deadPlayer.uid else {
                assert(false)
                return
            }
            self?.killedPlayer = PollingUser(
                id: uid, nickname: deadPlayer.nickName, avatar: deadPlayer.avatar.resourceName,
                color: Color(deadPlayer.color.color), isImposter: isImpostor)
        }).disposed(by: disposeBag)

        model.seconds.subscribe(onNext: { [weak self] seconds in
            self?.remainingTime = seconds
        }).disposed(by: disposeBag)

        model.allPlayers.subscribe(onNext: { [weak self] players in
            self?.allUsers = players.compactMap({ player in
                guard let uid = player.uid else {
                    return nil
                }
                let isImpostor = player is Impostor
                return PollingUser(
                    id: uid, nickname: player.nickName, avatar: player.avatar.resourceName,
                    color: Color(player.color.color), isImposter: isImpostor)
            })
        }).disposed(by: disposeBag)

        model.skipped.subscribe(onNext: { [weak self] in
            self?.skipped = ()
        }).disposed(by: disposeBag)
        model.isImpostor.subscribe(onNext: { [weak self] isImpostor in
            self?.isImpostor = isImpostor
        }).disposed(by: disposeBag)

        currentPoll = model.currentPollValue

        model.currentPoll.subscribe(onNext: { [weak self] poll in
            self?.currentPoll = poll
            print(poll)
        }).disposed(by: disposeBag)
    }

    func vote() {
        if isPollOrSkipped {
            return
        }
        guard let selectedUser = selectedUser else {
            return
        }
        model.decidePolled(playerID: selectedUser.id).subscribe({ _ in
            self.isPollOrSkipped = true
        }).disposed(by: disposeBag)
    }

    func skip() {
        if isPollOrSkipped {
            return
        }
        model.skip().subscribe({ _ in
            self.isPollOrSkipped = true
        }).disposed(by: disposeBag)
    }
}
