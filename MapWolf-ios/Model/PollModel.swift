//
//  PollModel.swift
//  MapWolf-ios
//
//  Created by fumiyatanaka_admin on 2021/01/28.
//

import Foundation
import RxRelay
import RxSwift

enum PlayerModelImplConst {
    static let pollMeetingSeconds: Int = 20
}

protocol PollModelType {
    var currentPollValue: Poll? { get }
    var currentPoll: Observable<Poll> { get }
    var isImpostor: Observable<Bool> { get }
    var skipped: Observable<Void> { get }
    var allPlayers: Observable<[Player]> { get }
    var deadPlayer: Observable<(player: Candidate, isImpostor: Bool)> { get }
    var seconds: Observable<Int> { get }

    func decidePolled(playerID: String) -> Single<Void>
    func skip() -> Single<Void>
}

class PollModel: PollModelType {
    private let pollTimeRelay: BehaviorRelay<Int> = .init(
        value: PlayerModelImplConst.pollMeetingSeconds)
    private let skippedRelay: PublishRelay<Void> = .init()
    private var pollTimer: Timer?
    private let killedPlayersRelay: BehaviorRelay<[Player]> = .init(value: [])
    private let userDefaults: UserDefaults = .standard
    private let store = Store.shared
    private let notificationCenter: NotificationCenter = .default
    private let firestore: FirestoreClient = .init()
    private let deadPlayerDecidedRelay: PublishRelay<(player: Candidate, isImpostor: Bool)> =
        .init()
    private let disposeBag: DisposeBag = .init()
    private let currentPollRelay: BehaviorRelay<Poll?> = .init(value: nil)

    var deadPlayer: Observable<(player: Candidate, isImpostor: Bool)> {
        deadPlayerDecidedRelay.asObservable()
    }

    var seconds: Observable<Int> {
        pollTimeRelay.asObservable()
    }

    var skipped: Observable<Void> {
        skippedRelay.asObservable()
    }

    var isImpostor: Observable<Bool> {
        store.impostors.withLatestFrom(store.me.compactMap({ $0?.uid })) { impostors, uid in
            impostors.contains(where: { $0.uid == uid })
        }
    }

    var currentPollValue: Poll? {
        currentPollRelay.value
    }

    var currentPoll: Observable<Poll> {
        currentPollRelay.compactMap({ $0 })
    }

    var allPlayers: Observable<[Player]> {
        killedPlayersRelay.withLatestFrom(store.players) { killed, players in
            players.filter({ player in !killed.contains(where: { $0.uid == player.uid }) })
        }
    }

    private var impostors: Observable<[Impostor]> {
        store.impostors.asObservable()
    }

    init() {
        startPollTimer()

        let killedByImpostor = store.impostors.map { $0.map { $0.killedCrewmates } }.map {
            array -> [Player] in
            var result = [Player]()
            array.forEach { crewmates in
                result.append(contentsOf: crewmates)
            }
            return result
        }
        let killedByPoll: Observable<[Player]> = store.polls.map {
            $0.compactMap { poll in poll.deadPlayer }
        }
        Observable.combineLatest(killedByPoll, killedByImpostor).map({ $0 + $1 }).bind(
            to: killedPlayersRelay
        ).disposed(by: disposeBag)

        Observable.combineLatest(store.polls, store.room.compactMap { $0 }).map({
            polls, room -> Poll? in
            guard let startDateInRoom = room.lastPollingStartDate else {
                return nil
            }
            let value = polls.first(where: { startDateInRoom.distance(to: $0.date) < 1 })
            return value
        }).bind(to: currentPollRelay).disposed(by: disposeBag)

        currentPoll.compactMap({ $0.deadPlayer }).withLatestFrom(store.impostors) {
            deadPlayer, impostors in
            var isImpostor: Bool = false
            if impostors.contains(where: { $0.uid == deadPlayer.uid }) {
                isImpostor = true
            }
            return (deadPlayer, isImpostor)
        }.distinctUntilChanged({ prev, next -> Bool in
            prev.player.uid == next.player.uid
        }).bind(to: deadPlayerDecidedRelay).disposed(by: disposeBag)

        currentPoll.filter({ $0.isSkipped }).distinctUntilChanged({ prev, next -> Bool in
            prev.uid == next.uid
        }).map({ _ in () }).bind(to: skippedRelay).disposed(
            by: disposeBag)

        pollTimeRelay.filter({ $0 <= 0 }).subscribe(onNext: { [weak self] _ in
            self?.stopPollTimer()
        }).disposed(by: disposeBag)

        pollTimeRelay.filter({ $0 <= 0 }).subscribe(onNext: { [weak self] _ in
            guard var poll = self?.currentPollRelay.value, let myUID = self?.store.me.value?.uid
            else {
                return
            }
            if poll.explicitSkipUserIDList.contains(myUID) {
                return
            }
            poll.explicitSkipUserIDList.append(myUID)
            self?.firestore.writeTransaction(
                poll,
                handler: { server, _ -> Poll in
                    var server = server
                    var finishedPollUserIDList: [String] = []
                    server.result.map({ $0.value }).forEach({
                        finishedPollUserIDList.append(contentsOf: $0)
                    })
                    if finishedPollUserIDList.contains(myUID) {
                        return server
                    }
                    if server.explicitSkipUserIDList.contains(myUID) {
                        return server
                    }
                    server.explicitSkipUserIDList.append(myUID)
                    return server
                },
                success: { _ in
                },
                failure: { error in
                    assert(false, error.localizedDescription)
                })
        }).disposed(by: disposeBag)

        notificationCenter.addObserver(forName: .didBecomeActive, object: nil, queue: .main) { _ in
            let willResignActiveAt = Date(
                timeIntervalSince1970: self.userDefaults.double(forKey: "willResignActive"))
            let diff = Int(Date().timeIntervalSince(willResignActiveAt))
            var calcTime = self.pollTimeRelay.value
            calcTime -= diff
            self.pollTimeRelay.accept(calcTime)
            self.startPollTimer()
        }

        notificationCenter.addObserver(forName: .willResignActive, object: nil, queue: .main) {
            [weak self] _ in
            self?.userDefaults.set(Date().timeIntervalSince1970, forKey: "willResignActive")
            self?.stopPollTimer()
        }
    }

    func decidePolled(playerID: String) -> Single<Void> {
        guard let player = store.players.value.first(where: { $0.uid == playerID }) else {
            return .never()
        }
        return Single.create { [weak self] singleEvent -> Disposable in
            guard let me = self?.store.me.value, let myUID = me.uid,
                let poll = self?.store.polls.value.sorted(by: { $0.date > $1.date }).first,
                let playerID = player.uid
            else {
                fatalError()
            }
            var result = poll.result
            if var dic = result[playerID] {
                dic.append(myUID)
            } else {
                result[playerID] = [myUID]
            }
            self?.firestore.writeTransaction(poll) { onServer, _ -> Poll in
                var onServer = onServer
                if var dic = onServer.result[playerID] {
                    dic.append(myUID)
                    onServer.result[playerID] = dic
                } else {
                    onServer.result[playerID] = [myUID]
                }
                return onServer
            } success: { _ in
                singleEvent(.success(()))
            } failure: { error in
                singleEvent(.failure(error))
                assert(false, error.localizedDescription)
            }
            return Disposables.create()
        }
    }

    func skip() -> Single<Void> {
        Single.create { [weak self] _ -> Disposable in
            guard var currentPoll = self?.currentPollRelay.value,
                let myUID = self?.store.me.value?.uid
            else {
                return Disposables.create()
            }
            if currentPoll.explicitSkipUserIDList.contains(myUID) {
                return Disposables.create()
            }
            currentPoll.explicitSkipUserIDList.append(myUID)
            self?.firestore.writeTransaction(
                currentPoll,
                handler: { server, _ -> Poll in
                    var server = server
                    var finishedPollUserIDList: [String] = []
                    server.result.map({ $0.value }).forEach({
                        finishedPollUserIDList.append(contentsOf: $0)
                    })
                    if finishedPollUserIDList.contains(myUID) {
                        return server
                    }
                    if server.explicitSkipUserIDList.contains(myUID) {
                        return server
                    }
                    server.explicitSkipUserIDList.append(myUID)
                    return server
                },
                success: { _ in
                },
                failure: { error in
                    assert(false, error.localizedDescription)
                })
            return Disposables.create()
        }
    }

    private func stopPollTimer() {
        pollTimer?.invalidate()
    }

    private func startPollTimer() {
        pollTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let time = self.pollTimeRelay.value
            self.pollTimeRelay.accept(time - 1)
        }
        self.pollTimer = timer
    }
}
