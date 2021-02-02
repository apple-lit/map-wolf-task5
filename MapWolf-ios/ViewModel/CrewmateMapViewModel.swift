//
//  CrewmateMapViewModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/21.
//

import Combine
import CoreLocation
import RxRelay
import RxSwift
import SwiftUI

class CrewmateMapViewModel: ObservableObject {
    private let showMyQRCodeRelay: PublishRelay<String> = .init()
    private let model = CrewmateModel()
    private let disposeBag = DisposeBag()
    private var cancellables: [AnyCancellable] = []

    @Published var spotTasks: [SpotTask] = []
    @Published var cooperateTasks: [CooperateTaskUser] = [
        CooperateTaskUser(id: 0, avatarText: "👾", color: .blue),
        CooperateTaskUser(id: 1, avatarText: "👾", color: .blue),
        CooperateTaskUser(id: 2, avatarText: "👾", color: .blue),
        CooperateTaskUser(id: 3, avatarText: "👾", color: .blue),
        CooperateTaskUser(id: 4, avatarText: "👾", color: .blue),
        CooperateTaskUser(id: 5, avatarText: "👾", color: .blue)
    ]
    @Published var showScanView: CooperateTask?
    @Published var completedCooperateTasks: [CooperateTaskUser] = []
    @Published var showMyQRCode: String = ""
    @Published var userSpotTasks: [UserSpotTask] = []
    @Published var canEmergency = false
    @Published var didTapTaskButton: Void = ()
    @Published var canStartTask: Bool = false
    @Published var canShowNearTaskButton: Bool = false

    @Published var presentPollingView: Void = ()
    @Published var presentSipoleTaskViewController: Void = ()
    @Published var currentSpotTask: SpotTask?
    @Published var isKilled: Bool = false
    @Published var winnerRole: PlayerRole = .unknown
    private var currentCooperateTask: CooperateTask?

    init() {
        Observable.combineLatest(model.spotTasks, model.completeSpotTaskList).subscribe(onNext: {
            [weak self] spotTasks, completeIDList in
            self?.spotTasks = spotTasks
            self?.userSpotTasks = spotTasks.map {
                UserSpotTask(
                    id: $0.id, isCompleted: completeIDList.contains($0.id),
                    color: Color(UIColor(hex: $0.colorHex)))
            }
        }).disposed(by: disposeBag)

        Observable.combineLatest(model.cooperateTasks, model.completeCooperateTaskList).subscribe {
            [weak self] cooperateTasks, completeIDList in
            self?.currentCooperateTask =
                cooperateTasks.filter({ task in !completeIDList.contains(task.id) }).first
            let tasks = cooperateTasks.map {
                CooperateTaskUser(
                    id: $0.id,
                    avatarText: $0.avatar?.resourceName ?? Avatar.defaultAvatar.resourceName,
                    color: Color(($0.color ?? PlayerColor.red).color))
            }
            self?.completedCooperateTasks = tasks.filter { completeIDList.contains($0.id) }
            self?.cooperateTasks = tasks
        }.disposed(by: disposeBag)

        model.currentSpotTask.distinctUntilChanged().subscribe(onNext: { [weak self] currentTask in
            self?.currentSpotTask = currentTask
            self?.canShowNearTaskButton = currentTask != nil
            self?.canStartTask = true
        }).disposed(by: disposeBag)

        showMyQRCodeRelay.subscribe { [weak self] string in
            self?.showMyQRCode = string
        }.disposed(by: disposeBag)

        model.location.map { location in
            location?.distance(
                from: CLLocation(
                    latitude: Constant.emergencyPoint.latitude,
                    longitude: Constant.emergencyPoint.longitude))
                ?? 100 < 50
        }.filter { [weak self] canEmergency in
            self?.canEmergency != canEmergency
        }.subscribe(onNext: { [weak self] canEmergency in
            if self?.isKilled ?? true {
                return
            }
            self?.canEmergency = canEmergency
        }).disposed(by: disposeBag)

        model.didStartPoll.filter({ self.isKilled == false }).subscribe(onNext: { [weak self] _ in
            self?.presentPollingView = ()
        }).disposed(by: disposeBag)

        model.isKilled.subscribe(onNext: { [weak self] isKilled in
            self?.isKilled = isKilled
        }).disposed(by: disposeBag)

        model.resultDecided.subscribe(onNext: { [weak self] winnerRole in
            self?.winnerRole = winnerRole
        }).disposed(by: disposeBag)

        $didTapTaskButton
            .dropFirst()
            .sink { [weak self] _ in
                if let nextCommonTask = self?.userSpotTasks.first(where: { $0.isCompleted == false }
                ) {
                    switch nextCommonTask.id {
                    case 0:
                        self?.presentSimpleTaskViewController()

                    default:
                        self?.presentSimpleTaskViewController()
                    }
                }
            }.store(in: &cancellables)
    }

    var locationManager: CLLocationManager {
        model.locationManager
    }

    var avatar: Avatar {
        model.me?.avatar ?? .defaultAvatar
    }

    func didTapShowMyQRCode() {
        guard let qrCode = model.me?.qrCode else {
            return
        }
        showMyQRCodeRelay.accept(qrCode)
    }

    func didTapShowScanView() {
        self.showScanView = currentCooperateTask
    }

    private func presentSimpleTaskViewController() {
        presentSipoleTaskViewController = ()
    }

    func didTapEmergencyButton() {
        if isKilled {
            return
        }
        model.startEmergencyMeeting().subscribe().disposed(by: disposeBag)
    }

    func didReport() {
        if isKilled {
            return
        }
        model.report().subscribe().disposed(by: disposeBag)
    }
}
