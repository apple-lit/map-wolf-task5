//
//  TaskModel.swift
//  MapWolf-ios
//
//  Created by fumiyatanaka_admin on 2021/01/30.
//

import AVFoundation
import RxRelay
import RxSwift

protocol SpotTaskModelType {
    func clearSpotTask(task: SpotTask) -> Single<Void>
}

protocol CooperateTaskModelType {
    var sessionHasStarted: Observable<Void> { get }
    var sessionHasStopped: Observable<Void> { get }
    var session: AVCaptureSession { get }
    var taskCompleted: Observable<CooperateTask> { get }
    func clearCooperateTask(task: CooperateTask) -> Single<Void>
}

class TaskModel: SpotTaskModelType, CooperateTaskModelType {
    private let store: Store = .shared
    private let firestore: FirestoreClient = .init()
    private let disposeBag: DisposeBag = .init()
    private let scanner: QRScaner = .init()
    private let taskCompletedRelay: PublishRelay<CooperateTask> = .init()
    private let qrDetectedRelay: PublishRelay<Candidate> = .init()

    var qrDetected: Observable<Candidate> {
        qrDetectedRelay.asObservable()
    }
    var session: AVCaptureSession {
        scanner.session
    }

    var sessionHasStarted: Observable<Void> {
        scanner.sessionHasStartedRelay.asObservable()
    }

    var taskCompleted: Observable<CooperateTask> {
        taskCompletedRelay.asObservable()
    }

    var sessionHasStopped: Observable<Void> {
        scanner.sessionHasStoppedRelay.asObservable()
    }

    init() {
        scanner.foundQR.debounce(.milliseconds(1), scheduler: ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] qrCode in
                guard let self = self else {
                    return
                }
                guard let room = self.store.room.value, let roomID = room.ref?.documentID else {
                    return
                }
                self.firestore.get(parent: roomID, docID: qrCode) { (candidate: Candidate) in
                    self.qrDetectedRelay.accept(candidate)
                } failure: { error in
                    assert(false, error.localizedDescription)
                }
            }).disposed(by: disposeBag)

        scanner.setupQRScan()
        scanner.startQRScan()

        qrDetectedRelay.distinctUntilChanged({ (prev: Candidate, next: Candidate) in
            prev.uid == next.uid
        }).withLatestFrom(store.me.compactMap({ $0 as? Crewmate })) {
            scanedUser, me -> CooperateTask? in
            guard
                var newTask = me.cooperateTasks.first(where: {
                    !me.completeCooperateTaskIDList.contains($0.id) && $0.qr == scanedUser.qrCode
                })
            else {
                return nil
            }
            newTask.qr = scanedUser.qrCode
            newTask.color = scanedUser.color
            newTask.avatar = scanedUser.avatar
            return newTask
        }.compactMap({ $0 }).flatMap({ cooperateTask in
            self.clearCooperateTask(task: cooperateTask).map { _ in cooperateTask }
        }).bind(to: taskCompletedRelay).disposed(by: disposeBag)
    }

    deinit {
        scanner.stopQRScan()
    }

    func clearSpotTask(task: SpotTask) -> Single<Void> {
        Single.create { singleEvent -> Disposable in
            guard var me = self.store.me.value as? Crewmate else {
                return Disposables.create()
            }
            me.completeSpotTaskIDList.append(task.id)
            self.firestore.write(me, merge: true) { _ in
                singleEvent(.success(()))
            } failure: { (error: Error) in
                assert(false, error.localizedDescription)
            }
            return Disposables.create()
        }
    }

    func clearCooperateTask(task: CooperateTask) -> Single<Void> {
        Single.create { singleEvent -> Disposable in
            guard var me = self.store.me.value as? Crewmate else {
                return Disposables.create()
            }
            if me.completeCooperateTaskIDList.contains(task.id) {
                return Disposables.create()
            }
            me.completeCooperateTaskIDList.append(task.id)
            self.firestore.write(me, merge: true) { _ in
                singleEvent(.success(()))
            } failure: { (error: Error) in
                assert(false, error.localizedDescription)
            }
            return Disposables.create()
        }
    }
}
