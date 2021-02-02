//
//  RoomViewModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import AVFoundation
import Combine
import RxRelay
import RxSwift
import SwiftUI

class RoomViewModel: ObservableObject {
    private let model: RoomModelType = RoomModel()
    private let disposeBag = DisposeBag()
    private var cancellables: [AnyCancellable] = []
    let previewLayer = AVCaptureVideoPreviewLayer()

    var session: AVCaptureSession {
        model.session
    }

    // Both Host and Guest
    @Published var updateUIView: Void = ()  // READ ONLY
    @Published var playerRole = PlayerRole.crewmate  // READ ONLY
    @Published var playerNames: [String] = []  // READ ONLY
    @Published var playerCount: Int = 0  // READ ONLY
    @Published var maximumPlayerCount: Int = 0  // READ ONLY
    @Published var readyForGame: Void = ()  // READ ONLY
    @Published var confirmedPlayerRole: Void = ()  // Read / Write
    @Published var backToLoginView: Void = ()  // Read / Write

    // Guest
    @Published var myNickName: String = ""
    @Published var myColor = Color.red
    @Published var myAvatarResourceName: String = Avatar.defaultAvatar.resourceName
    @Published var didEnterRoom: Void = ()
    @Published var backToScanRoomView: Void = ()  // READ ONLY
    @Published var hostName: String = ""  // READ ONLY
    @Published var hostAvatarText: String = ""  // READ ONLY
    @Published var hostColor = Color.red  // READ ONLY
    @Published var didDetectRoom: Void = ()
    // Host
    @Published var impostorCount: Int = 0  // Read / Write
    @Published var didCreateQRImage: UIImage?  // READ ONLY

    init() {
        // Subscribe
        model.me.map { $0.role }.subscribe(onNext: { [weak self] role in
            self?.playerRole = role
        }).disposed(by: disposeBag)

        model.players.map { $0.count }.subscribe(onNext: { [weak self] count in
            self?.playerCount = count
        }).disposed(by: disposeBag)

        model.players.map { $0.map { $0.nickName } }.subscribe(onNext: { [weak self] names in
            self?.playerNames = names
        }).disposed(by: disposeBag)

        model.gameStart.subscribe(onNext: { [weak self] in
            self?.readyForGame = ()
        }).disposed(by: disposeBag)

        model.room.map { $0?.maximumPlayersCount ?? 0 }.distinctUntilChanged().subscribe(onNext: {
            [weak self] count in
            self?.maximumPlayerCount = count
        }).disposed(by: disposeBag)

        model.room.compactMap { $0?.impostorCount }.distinctUntilChanged().subscribe(onNext: {
            [weak self] count in
            self?.impostorCount = count
        }).disposed(by: disposeBag)

        model.host.subscribe(onNext: { [weak self] host in
            self?.hostName = host.nickName
            self?.hostColor = Color(host.color.color)
            self?.hostAvatarText = host.avatar.resourceName
        }).disposed(by: disposeBag)

        model.didDetectRoom.subscribe(onNext: { [weak self] in
            self?.didDetectRoom = ()
        }).disposed(by: disposeBag)

        model.sessionHasStarted.observe(on: MainScheduler.instance).subscribe(onNext: {
            [weak self] in
            guard let self = self else {
                return
            }
            self.previewLayer.session = self.session
            self.previewLayer.videoGravity = .resizeAspectFill
            self.updateUIView = ()
        }).disposed(by: disposeBag)

        model.me.withLatestFrom(model.room.compactMap { $0 }) { me, room -> Candidate? in
            if room.hostID == me.uid {
                return nil
            }
            return me
        }.compactMap { $0 }.map { _ in () }.subscribe(onNext: { [weak self] in
            self?.didEnterRoom = ()
        }).disposed(by: disposeBag)

        model.me.compactMap { $0.avatar.resourceName }.subscribe(onNext: {
            [weak self] resourceName in
            self?.myAvatarResourceName = resourceName
        }).disposed(by: disposeBag)

        model.me.compactMap { $0.color.color }.subscribe(onNext: { [weak self] color in
            self?.myColor = Color(color)
        }).disposed(by: disposeBag)
    }

    func increaseImpostorCount() {
        let count = impostorCount + 1
        model.changeImpostorCount(count)
    }

    func decreaseImpostorCount() {
        let count = impostorCount - 1
        model.changeImpostorCount(count)
    }

    func didTapBackButtonAtRoomScan() {
        backToLoginView = ()
    }

    func didTapHostBackButton() {
        backToScanRoomView = ()
    }

    func didTapGuestBackButton() {
        backToScanRoomView = ()
    }

    func startScanning() {
        model.startScanning()
    }

    func stopScanning() {
        model.stopScanning()
    }

    func didTapConfirmRoomButton() {
        guard let qr = model.foundQRText else {
            return
        }
        self.model.join(id: qr).subscribe().disposed(by: self.disposeBag)
    }

    // Hostがゲーム開始ボタンをタップした
    func didTapGameStartButton() {
        model.startGame()
    }

    // Become Host
    func becomeHost() {
        model.create().subscribe(onSuccess: { [weak self] room in
            let id = room.searchID
            MVQRGenerator.generate(text: id) { image in
                self?.didCreateQRImage = image
            }
        }).disposed(by: disposeBag)
    }
}
