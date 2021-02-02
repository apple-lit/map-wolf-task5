//
//  PlayerModelImpl.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import CoreLocation
import FirebaseFirestore
import FirebaseFirestoreSwift
import RxRelay
import RxSwift

class PlayerModelImpl<PlayerModel: Player>: NSObject, PlayerModelType {
    typealias P = PlayerModel

    let killedPlayersRelay: BehaviorRelay<[Player]> = .init(value: [])
    let userDefauts: UserDefaults = .standard
    let _locationManager: LocationManager = .init()
    let firestore = FirestoreClient()
    let firebaseFirestore: Firestore = .firestore()
    let auth: AuthClientType = AuthClient()
    let gameResult: PublishRelay<PlayerRole> = .init()
    let lastPollingDateRelay: PublishRelay<Date> = .init()
    let store: Store
    var pollingWithFirestoreTimer: Timer?
    let disposeBag: DisposeBag = .init()

    let didStartPollRelay: BehaviorRelay<Poll?> = .init(value: nil)

    var locationManager: CLLocationManager {
        _locationManager
    }

    var location: Observable<CLLocation?> {
        _locationManager.locationRelay.asObservable()
    }

    var crewmates: Observable<[Crewmate]> {
        store.crewmates.asObservable()
    }

    var impostors: Observable<[Impostor]> {
        store.impostors.asObservable()
    }

    var killedPlayers: Observable<[Player]> {
        killedPlayersRelay.asObservable()
    }

    var isKilled: Observable<Bool> {
        killedPlayers.map { $0.contains(where: { $0.uid == self.me?.uid }) }
    }

    var me: P? {
        store.me.value as? P
    }

    var meObservable: Observable<PlayerModel> {
        store.me.compactMap { $0 as? P }
    }

    var resultDecided: Observable<PlayerRole> {
        gameResult.filter({ $0 != .unknown })
    }

    var didStartPoll: Observable<Void> {
        lastPollingDateRelay.map { _ in () }
    }

    init(store: Store = .shared) {
        self.store = store
        super.init()

        // Update Location mandatory
        _locationManager.locationRelay.compactMap({ $0 }).take(1).subscribe(onNext: {
            [weak self] location in
            let playerLocation = PlayerLocation(
                latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            guard var me = self?.me else {
                return
            }
            me.location = playerLocation
            self?.firestore.write(
                me, merge: true,
                success: { _ in
                },
                failure: { error in
                    print(error)
                })
        }).disposed(by: disposeBag)

        // Timer
        startPollingWithFirestore()

        let killedByImpostor = impostors.map { $0.map { $0.killedCrewmates } }.map {
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

        store.room
            .compactMap({ $0?.lastPollingStartDate })
            .bind(to: lastPollingDateRelay)
            .disposed(by: disposeBag)

        killedPlayers.withLatestFrom(impostors) { ($0, $1) }.map { killedPlayers, impostors in
            let killAllImpostors = impostors.allSatisfy({ impostor in
                killedPlayers.contains(where: { impostor.uid == $0.uid })
            })
            if killAllImpostors {
                return PlayerRole.crewmate
            }
            let aliveCrewmateCount = self.store.crewmates.value.filter({ player in
                !killedPlayers.contains(where: { killed in killed.uid == player.uid })
            }).compactMap({ $0 }).count
            let aliveImpostorCount = self.store.impostors.value.filter({ player in
                !killedPlayers.contains(where: { killed in killed.uid == player.uid })
            }).compactMap({ $0 }).count

            if aliveCrewmateCount < aliveImpostorCount {
                return PlayerRole.impostor
            }
            return PlayerRole.unknown
        }.bind(to: gameResult).disposed(by: disposeBag)

        store.room
            .compactMap({ $0 })
            .filter({ $0.isAllTaskDone })
            .map({ _ in PlayerRole.crewmate })
            .bind(to: gameResult)
            .disposed(by: disposeBag)
    }

    func report() -> Single<Void> {
        guard var room = store.room.value, let roomRef = room.ref else {
            return .never()
        }
        return Single.create { [weak self] singleEvent -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            let killedPlayers = self.killedPlayersRelay.value
            let participants = self.store.candidates.value.filter({ player in
                !killedPlayers.contains(where: { player.uid == $0.uid })
            }).compactMap({ $0.uid })

            guard let myLocation = self.me?.location else {
                return Disposables.create()
            }

            let locationCalculator = LocationCalculator()
            let deadPlayer = self.store.candidates.value.filter({ candidate in
                killedPlayers.contains(where: { player in player.uid == candidate.uid })
            }).sorted(by: { prev, next in
                locationCalculator.getDistanceByMeter(
                    from: myLocation, to: prev.location ?? PlayerLocation.zero)
                    > locationCalculator.getDistanceByMeter(
                        from: myLocation, to: next.location ?? PlayerLocation.zero)
            }).first

            let current = Date()
            let poll = Poll(
                ref: nil, triggerPlayer: deadPlayer, result: [:], participants: participants,
                deadPlayer: nil, isEmergency: false, date: current, isSkipped: false,
                explicitSkipUserIDList: [])
            room.lastPollingStartDate = current

            let batch = self.firebaseFirestore.batch()
            do {
                try batch.setData(from: room, forDocument: roomRef)
                try batch.setData(
                    from: poll, forDocument: roomRef.collection(Poll.collectionName).document())
            } catch {
                singleEvent(.failure(error))
            }
            batch.commit { error in
                if let error = error {
                    singleEvent(.failure(error))
                    return
                }
                singleEvent(.success(()))
            }
            return Disposables.create()
        }
    }

    func startEmergencyMeeting() -> Single<Void> {
        guard var room = store.room.value, let roomRef = room.ref else {
            return .never()
        }
        return Single.create { [weak self] singleEvent -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            let killedPlayers = self.killedPlayersRelay.value
            let participants = self.store.candidates.value.filter({ player in
                !killedPlayers.contains(where: { player.uid == $0.uid })
            }).compactMap({ $0.uid })
            let current = Date()
            let poll = Poll(
                ref: nil, triggerPlayer: nil, result: [:], participants: participants,
                deadPlayer: nil,
                isEmergency: true, date: current, isSkipped: false, explicitSkipUserIDList: [])
            room.lastPollingStartDate = current

            let batch = self.firebaseFirestore.batch()
            do {
                try batch.setData(from: room, forDocument: roomRef)
                try batch.setData(
                    from: poll, forDocument: roomRef.collection(Poll.collectionName).document())
            } catch {
                singleEvent(.failure(error))
            }
            batch.commit { error in
                if let error = error {
                    singleEvent(.failure(error))
                    return
                }
                singleEvent(.success(()))
            }
            return Disposables.create()
        }
    }

    private func startPollingWithFirestore() {
        pollingWithFirestoreTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else {
                return
            }
            guard var me = self.me else {
                return
            }
            if let location = self._locationManager.location {
                let playerLocation = PlayerLocation(
                    latitude: location.coordinate.latitude, longitude: location.coordinate.longitude
                )
                me.location = playerLocation
                self.firestore.write(me, merge: true) { _ in
                } failure: { error in
                    assert(false, error.localizedDescription)
                }
            }
        }
        self.pollingWithFirestoreTimer = timer
    }

    private func stopPollingWithFirestoreTimer() {
        pollingWithFirestoreTimer?.invalidate()
    }
}
