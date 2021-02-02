//
//  CrewmateModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/27.
//

import CoreLocation
import RxRelay
import RxSwift
import UIKit

enum CrewmateMapConst {
    static let radius: Double = 50
}

protocol CrewmateModelType: PlayerModelType {
    var currentSpotTask: Observable<SpotTask?> { get }

    var didCompleteSpotTask: Observable<SpotTask> { get }
    var didCompleteCooperateTask: Observable<CooperateTask> { get }

    var spotTasks: Observable<[SpotTask]> { get }
    var cooperateTasks: Observable<[CooperateTask]> { get }

    var completeSpotTaskList: Observable<[Int]> { get }
    var completeCooperateTaskList: Observable<[Int]> { get }

    func clearTask(spotTask: SpotTask) -> Single<Void>
}

class CrewmateModel: PlayerModelImpl<Crewmate>, CrewmateModelType {
    // 現在エリア内にいるTaskを流す
    private let currentSpotTaskRelay: BehaviorRelay<SpotTask?> = .init(value: nil)
    // 完了したTaskを流す
    private let didCompleteSpotTaskRelay: PublishRelay<SpotTask> = .init()
    private let spotTasksRelay: BehaviorRelay<[SpotTask]> = .init(value: [])
    private let cooperateTasksRelay: BehaviorRelay<[CooperateTask]> = .init(value: [])
    private let completeSpotTaskIDLIstRelay: BehaviorRelay<[Int]> = .init(value: [])
    private let completeCooperateTaskIDListRelay: BehaviorRelay<[Int]> = .init(value: [])
    private let didCompleteCooperateTaskRelay: PublishRelay<CooperateTask> = .init()
    private let qeScanner = QRScaner()

    override init(store: Store = .shared) {
        super.init()
        Observable.combineLatest(
            _locationManager.locationRelay.compactMap { $0 }, _locationManager.inRegionRelay
        ).map { location, region -> SpotTask? in
            if region.contains(location.coordinate), let me = self.me {
                let totalSpotTasks = me.spotTasks.sorted(by: { $0.id < $1.id })
                let handler = SpotTaskHandler()
                guard
                    let nextTask = handler.getNextSpotTask(
                        tasks: totalSpotTasks, completedIDList: me.completeSpotTaskIDList)
                else {
                    return nil
                }
                let nextTaskLocation = CLLocationCoordinate2D(
                    latitude: nextTask.latitude, longitude: nextTask.longitude)
                if region.contains(nextTaskLocation) && region.identifier == "\(nextTask.id)" {
                    return nextTask
                }
            }
            return nil
        }.bind(to: currentSpotTaskRelay).disposed(by: disposeBag)
        qeScanner.foundQR.flatMap(scan(qrCode:)).bind(to: didCompleteCooperateTaskRelay).disposed(
            by: disposeBag)

        meObservable.subscribe(onNext: { [weak self] me in
            let completeSpotTaskIDLIst = me.completeSpotTaskIDList
            self?.completeSpotTaskIDLIstRelay.accept(completeSpotTaskIDLIst)
            self?.spotTasksRelay.accept(me.spotTasks.sorted(by: { $0.id < $1.id }))
            let completeCooperateTaskIDList = me.completeCooperateTaskIDList
            self?.completeCooperateTaskIDListRelay.accept(completeCooperateTaskIDList)
            self?.cooperateTasksRelay.accept(me.cooperateTasks)
        }).disposed(by: disposeBag)

        spotTasks.subscribe(onNext: { [weak self] tasks in
            guard let self = self else {
                return
            }
            self._locationManager.removeAllRegionsForMonitor()
            tasks.forEach {
                self._locationManager.addRegionToMonitor(
                    CLCircularRegion(
                        center: CLLocationCoordinate2D(
                            latitude: $0.latitude, longitude: $0.longitude),
                        radius: Double(CrewmateMapConst.radius), identifier: String($0.id)))
            }
        }).disposed(by: disposeBag)
    }

    var room: Room? {
        store.room.value
    }

    var currentSpotTask: Observable<SpotTask?> {
        currentSpotTaskRelay.asObservable()
    }

    var spotTasks: Observable<[SpotTask]> {
        spotTasksRelay.asObservable()
    }

    var cooperateTasks: Observable<[CooperateTask]> {
        cooperateTasksRelay.asObservable()
    }

    var didCompleteCooperateTask: Observable<CooperateTask> {
        didCompleteCooperateTaskRelay.asObservable()
    }

    var didCompleteSpotTask: Observable<SpotTask> {
        didCompleteSpotTaskRelay.asObservable()
    }

    var completeSpotTaskList: Observable<[Int]> {
        completeSpotTaskIDLIstRelay.asObservable()
    }

    var completeCooperateTaskList: Observable<[Int]> {
        completeCooperateTaskIDListRelay.asObservable()
    }

    private func scan(qrCode: String) -> Single<CooperateTask> {
        guard var me = me, let room = room, let myUID = me.uid else {
            return .never()
        }
        guard let cooperateTask = me.cooperateTasks.first(where: { $0.qr == qrCode }) else {
            return .never()
        }
        if me.completeCooperateTaskIDList.contains(cooperateTask.id) {
            // 既に使用したQRコード
            return .never()
        }

        me.completeCooperateTaskIDList.append(cooperateTask.id)
        // タスクの更新
        return Single.create { singleEvent -> Disposable in
            do {
                try room.ref?.collection("players").document(myUID).setData(
                    from: me,
                    completion: { error in
                        if let error = error {
                            singleEvent(.failure(error))
                            return
                        }
                        singleEvent(.success(cooperateTask))
                    })
            } catch {
                singleEvent(.failure(error))
            }
            return Disposables.create()
        }
    }

    func clearTask(spotTask: SpotTask) -> Single<Void> {
        Single.create { _ -> Disposable in
            guard var me = self.me, let roomRef = self.room?.ref else {
                return Disposables.create()
            }

            let handler = SpotTaskHandler()

            if !handler.validate(
                tasks: me.spotTasks, completedTaskIDList: me.completeSpotTaskIDList,
                clearedTask: spotTask) {
                return Disposables.create()
            }

            me.completeSpotTaskIDList.append(spotTask.id)
            self.firestore.write(me, parent: roomRef.documentID, merge: true) { _ in
            } failure: { error in
                assert(false, error.localizedDescription)
            }
            return Disposables.create()
        }
    }
}
