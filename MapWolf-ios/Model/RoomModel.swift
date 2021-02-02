//
//  RoomModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import AVFoundation
import Foundation
import RxRelay
import RxSwift

enum RoomModelError: Error {
    case noDisplayName
}

protocol RoomModelType {
    var gameStart: Observable<Void> { get }
    var players: Observable<[Candidate]> { get }
    var me: Observable<Candidate> { get }
    var foundQRText: String? { get }
    var sessionHasStarted: Observable<Void> { get }
    var sessionHasStopped: Observable<Void> { get }
    var host: Observable<Candidate> { get }
    var room: Observable<Room?> { get }
    var didDetectRoom: Observable<Void> { get }
    var session: AVCaptureSession { get }
    func create() -> Single<Room>
    func join(id: String) -> Single<Room>
    func leave(_ player: Player, from room: Room) -> Single<Void>
    func changeImpostorCount(_ count: Int)
    func startGame()
    func startScanning()
    func stopScanning()
}

class RoomModel: RoomModelType {
    private let scanner: QRScaner = .init()
    private let candidatesRelay: BehaviorRelay<[Candidate]> = .init(value: [])
    private let gameStartRelay: PublishRelay<Void> = .init()
    private let didDetectRoomRelay: PublishRelay<Void> = .init()
    private let hostRelay: PublishRelay<Candidate> = .init()
    private let firestore = FirestoreClient()
    private let taskGenerator: TaskGenerator = .init()
    private let store: Store = .shared
    private let disposeBag = DisposeBag()

    var didDetectRoom: Observable<Void> {
        didDetectRoomRelay.asObservable()
    }

    var sessionHasStarted: Observable<Void> {
        scanner.sessionHasStartedRelay.asObservable()
    }

    var sessionHasStopped: Observable<Void> {
        scanner.sessionHasStoppedRelay.asObservable()
    }

    var gameStart: Observable<Void> {
        gameStartRelay.asObservable()
    }

    var players: Observable<[Candidate]> {
        candidatesRelay.asObservable()
    }

    var me: Observable<Candidate> {
        store.me.compactMap { $0 as? Candidate }
    }

    var room: Observable<Room?> {
        store.room.asObservable()
    }

    var host: Observable<Candidate> {
        hostRelay.asObservable()
    }

    var session: AVCaptureSession {
        scanner.session
    }

    var foundQRText: String?

    init() {
        store.players.map { $0.compactMap { player in player as? Candidate } }.bind(
            to: candidatesRelay
        )
        .disposed(by: disposeBag)

        store.me.compactMap { $0 }.filter { $0.role != .unknown }.take(1).withLatestFrom(players) {
            ($0, $1)
        }.subscribe(onNext: { [weak self] me, players in
            guard let self = self else {
                return
            }
            if me.role == .crewmate {
                var crewmate = Crewmate(
                    ref: me.ref, uid: me.ref?.documentID, nickName: me.nickName, spotTasks: [],
                    cooperateTasks: [], completeCooperateTaskIDList: [], completeSpotTaskIDList: [],
                    qrCode: me.qrCode, avatar: me.avatar, color: me.color, role: me.role,
                    location: me.location, isSabotaged: false)
                let cooperateTasks = self.taskGenerator.configureCooperateTasksAvatar(
                    of: crewmate, players: players)
                crewmate = self.taskGenerator.configureTask(
                    of: crewmate, cooperates: cooperateTasks, spots: spotTasks)
                self.firestore.write(crewmate, merge: true) { [weak self] _ in
                    self?.gameStartRelay.accept(())
                } failure: { error in
                    assert(false, error.localizedDescription)
                }
            } else if me.role == .impostor {
                let impostor = Impostor(
                    ref: me.ref, uid: me.ref?.documentID, nickName: me.nickName,
                    killedCrewmates: [],
                    qrCode: me.qrCode, avatar: me.avatar, color: me.color, role: me.role,
                    location: me.location)
                self.firestore.write(impostor, merge: true) { [weak self] _ in
                    self?.gameStartRelay.accept(())
                } failure: { error in
                    assert(false, error.localizedDescription)
                }
            }
        }).disposed(by: disposeBag)
        scanner.foundQR.debounce(.milliseconds(1), scheduler: ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] qrCode in
                guard let self = self else {
                    return
                }
                self.foundQRText = qrCode
                self.firestore.get(filter: [.init(fieldPath: "searchID", value: qrCode)]) {
                    (rooms: [Room]) in
                    if let room = rooms.first {
                        self.store.room.accept(room)
                        self.didDetectRoomRelay.accept(())
                    }
                } failure: { error in
                    assert(false, error.localizedDescription)
                }
            }).disposed(by: disposeBag)
        room.compactMap { $0?.hostID }.distinctUntilChanged().subscribe(onNext: {
            [weak self] hostID in
            guard let roomRef = self?.store.room.value?.ref else {
                return
            }
            self?.firestore.get(
                parent: roomRef.documentID, docID: hostID,
                success: { (host: Candidate) in
                    self?.hostRelay.accept(host)
                },
                failure: { _ in
                    assert(false)
                })
        })
        .disposed(by: disposeBag)
        scanner.setupQRScan()
    }

    private func giveRoll(_ players: [Candidate], room: Room, completion: (() -> Void)?) {
        // Rollの更新をおこなう為のバッチ
        var newPlayers: [Candidate] = []
        if players.count < 2 {
            return
        }
        let indexes = ImpostorGenerator().decideImpostorIndexes(from: room, players: players)
        for (index, var player) in players.enumerated() {
            if indexes.contains(index) {
                player.role = PlayerRole.impostor
            } else {
                player.role = .crewmate
            }
            guard let ref = room.ref, let uid = player.uid else {
                continue
            }
            let playerRef = ref.collection("players").document(uid)
            player.ref = playerRef
            newPlayers.append(player)
        }
        firestore.batch(models: newPlayers) { error in
            if let error = error {
                assert(false, error.localizedDescription)
                return
            }
            completion?()
        }
    }

    func create() -> Single<Room> {
        Single.create { singleEvent -> Disposable in
            guard let user = self.store.user.value else {
                return Disposables.create()
            }
            guard let displayName = user.displayName else {
                return Disposables.create()
            }
            let color = self.store.color
            let avatar = self.store.avatar
            // ランダムなIDを作成（6桁の数字）
            let numbers: [String] = (0...9).map { String($0) }
            let id: String = (0...5).map { _ in numbers.randomElement()! }.joined()
            var room = Room(
                ref: nil, searchID: id, hostID: user.uid,
                crewmateTaskProgress: [user.uid: 0])
            var candidate = Candidate(
                uid: user.uid, qrCode: user.uid, nickName: displayName, color: color, avatar: avatar
            )
            self.firestore.write(room, merge: true) { roomRef in
                candidate.ref = roomRef.collection(Candidate.collectionName).document(user.uid)
                self.firestore.write(candidate, parent: roomRef.documentID, merge: true) {
                    _ in
                    room.ref = roomRef
                    self.store.room.accept(room)
                    singleEvent(.success(room))
                } failure: { error in
                    singleEvent(.failure(error))
                }
            } failure: { error in
                singleEvent(.failure(error))
            }
            return Disposables.create()
        }
    }

    func join(id: String) -> Single<Room> {
        Single.create { singleEvent -> Disposable in
            guard let user = self.store.user.value else {
                return Disposables.create()
            }
            guard let displayName = user.displayName else {
                return Disposables.create()
            }
            self.firestore.get(filter: [.init(fieldPath: "searchID", value: id)]) {
                (rooms: [Room]) in
                guard let room = rooms.first, let roomID = room.ref?.documentID else {
                    return
                }
                guard
                    let candidateRef = room.ref?.collection(Candidate.collectionName).document(
                        user.uid)
                else {
                    return
                }
                let color = self.store.color
                let avatar = self.store.avatar
                let cancidate = Candidate(
                    ref: candidateRef, uid: candidateRef.documentID, qrCode: user.uid,
                    nickName: displayName,
                    color: color, avatar: avatar)
                self.firestore.write(cancidate, parent: roomID, merge: true) { _ in
                    singleEvent(.success(room))
                } failure: { error in
                    singleEvent(.failure(error))
                }
            } failure: { error in
                singleEvent(.failure(error))
            }
            return Disposables.create()
        }
    }

    func startGame() {
        guard let room = store.room.value else {
            return
        }
        giveRoll(candidatesRelay.value, room: room, completion: nil)
    }

    func leave(_ player: Player, from room: Room) -> Single<Void> {
        return Single.create { singleEvent -> Disposable in
            guard let uid = player.uid else {
                return Disposables.create()
            }
            guard let roomRef = room.ref else {
                return Disposables.create()
            }
            roomRef.collection("players").document(uid).delete { error in
                if let error = error {
                    singleEvent(.failure(error))
                    return
                }
                singleEvent(.success(()))
            }
            return Disposables.create()
        }
    }

    func changeImpostorCount(_ count: Int) {
        guard var room = store.room.value else {
            return
        }
        if store.candidates.value.count < count || count < 0 {
            return
        }
        room.impostorCount = count
        firestore.write(room, merge: true) { _ in
        } failure: { error in
            assert(false, error.localizedDescription)
        }
    }

    func startScanning() {
        scanner.startQRScan()
    }

    func stopScanning() {
        scanner.stopQRScan()
    }
}
