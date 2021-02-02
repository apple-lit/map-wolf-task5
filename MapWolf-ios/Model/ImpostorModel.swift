//
//  ImpostorModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import CoreLocation
import RxRelay
import RxSwift
import UIKit

enum ImpostorModelConst {
    static let killCoolTime: Int = 60
    static let sabotageTime: Int = 60
    static let killableDistance: Double = 20
}

class ImpostorModel: PlayerModelImpl<Impostor>, ImpostorModelType {
    private var killCoolTimer = BackgroundTimer(
        initialTime: ImpostorModelConst.killCoolTime)
    private var sabotageCoolTimer = BackgroundTimer(
        initialTime: ImpostorModelConst.sabotageTime)
    private let canKillRelay: BehaviorRelay<Bool> = .init(value: false)
    private let locationCalculator: LocationCalculator = .init()

    var sabotageCoolTime: Observable<Int> {
        sabotageCoolTimer.relay.asObservable()
    }

    var killCoolTime: Observable<Int> {
        killCoolTimer.relay.asObservable()
    }

    var canKill: Observable<Bool> {
        canKillRelay.asObservable()
    }

    func kill() -> Single<Crewmate> {
        Single<Crewmate>.create { [weak self] singleEvent -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            guard var me = self.me, let myLocation = self.locationManager.location else {
                return Disposables.create()
            }
            let playerLocation = self.locationCalculator.convert(myLocation.coordinate)
            guard
                let crewmate = self.getKillableCrewmates(
                    myLocation: playerLocation, crewmates: self.store.crewmates.value
                ).first
            else {
                return Disposables.create()
            }
            if me.killedCrewmates.contains(where: { $0.uid == crewmate.uid }) {
                return Disposables.create()
            }
            me.killedCrewmates.append(crewmate)
            self.firestore.write(me, merge: true) { _ in
                singleEvent(.success(crewmate))
                // killCoolTimeの更新
                self.startKillCoolTimer()
            } failure: { error in
                assert(false, error.localizedDescription)
            }
            return Disposables.create()
        }
    }

    func sabotage() -> Single<Void> {
        Single.create { [weak self] single -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            if self.sabotageCoolTimer.relay.value > 0 {
                return Disposables.create()
            }
            var crewmates = self.store.players.value.compactMap { $0 as? Crewmate }
            let coordinate = taskLocationCandidates.randomElement()!
            crewmates = crewmates.map({ crewmate in
                var crewmate = crewmate

                let handler = SpotTaskHandler()
                var (newTaskList, sabotagedID): ([SpotTask], Int) =
                    handler.getSabotagedIDAndNewTasks(
                        from: crewmate.spotTasks,
                        completedTaskIDList: crewmate.completeSpotTaskIDList)

                let sabotagedTask = SpotTask(
                    id: sabotagedID, latitude: coordinate.lat, longitude: coordinate.long,
                    next: sabotagedID + 1, preivous: sabotagedID - 1,
                    colorHex: UIColor.systemTeal.hexString,
                    isSabotaged: true)

                newTaskList.append(sabotagedTask)
                crewmate.spotTasks = newTaskList

                return crewmate
            })
            self.firestore.batch(models: crewmates) { error in
                if let error = error {
                    single(.failure(error))
                }
            }
            self.sabotageCoolTimer.startTimer(fromBeforeState: false)
            return Disposables.create()
        }
    }

    override init(store: Store = .shared) {
        super.init(store: store)
        crewmates.withLatestFrom(location.compactMap { $0 }) { (location: $1, crewmates: $0) }
            .flatMap(
                checkCanKillCrewmate(location:crewmates:)
            ).withLatestFrom(killCoolTimer.relay) { $0 && $1 <= 0 }.bind(to: canKillRelay).disposed(
                by: disposeBag)

        self.startKillCoolTimer()
        self.startSabotageCoolTimer()
    }

    private func checkCanKillCrewmate(location: CLLocation, crewmates: [Crewmate]) -> Observable<
        Bool
    > {
        Single.create { [weak self] singleEvent -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            let coordinate = self.locationCalculator.convert(location.coordinate)
            let crewmateCoordinates = crewmates.compactMap { $0.location }

            let result = crewmateCoordinates.contains(where: {
                self.locationCalculator.getDistanceByMeter(from: $0, to: coordinate)
                    < ImpostorModelConst.killableDistance
            })
            singleEvent(.success(result))

            return Disposables.create()
        }.asObservable()
    }

    private func getKillableCrewmates(myLocation: PlayerLocation, crewmates: [Crewmate])
        -> [Crewmate] {
        let result = crewmates.filter({ crewmate in
            guard let location = crewmate.location else {
                return false
            }
            return self.locationCalculator.getDistanceByMeter(from: location, to: myLocation)
                < ImpostorModelConst.killableDistance
        })
        return result
    }

    private func startKillCoolTimer() {
        killCoolTimer.startTimer()
    }

    private func startSabotageCoolTimer() {
        sabotageCoolTimer.startTimer()
    }
}
