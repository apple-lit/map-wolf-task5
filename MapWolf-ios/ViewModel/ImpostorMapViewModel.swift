//
//  ImpostorMapViewModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import Combine
import CoreLocation
import Foundation
import RxRelay
import RxSwift
import SwiftUI

class ImpostorMapViewModel: ObservableObject {
    private let showMyQRCodeRelay: PublishRelay<String> = .init()
    private let model: ImpostorModel
    private let disposeBag: DisposeBag = .init()

    @Published var showMyQRCode: String = ""
    @Published var winnerRole: PlayerRole = .unknown
    @Published var killCoolTime: Int = 0
    @Published var killedCrewmate: Crewmate?
    @Published var startPoll: Void = ()
    @Published var isKilled: Bool = false
    @Published var canEmergency: Bool = false
    @Published var canKill: Bool = false
    @Published var avatar = Avatar.defaultAvatar
    var myCoordinate = CLLocationCoordinate2D(latitude: 40, longitude: 130)

    init(model: ImpostorModel) {
        self.model = model

        model.canKill
            .subscribe(onNext: { [weak self] canKill in
                if self?.isKilled ?? true {
                    return
                }
                self?.canKill = canKill
            }).disposed(by: disposeBag)

        model.meObservable
            .subscribe(onNext: { [weak self] me in
                self?.avatar = me.avatar
            }).disposed(by: disposeBag)

        model.location
            .compactMap { $0?.coordinate }
            .subscribe(onNext: { [weak self] coordinate in
                self?.myCoordinate = coordinate
            }).disposed(by: disposeBag)

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

        model.isKilled
            .subscribe(onNext: { [weak self] isKilled in
                self?.isKilled = isKilled
            }).disposed(by: disposeBag)

        model.didStartPoll
            .filter({ self.isKilled == false })
            .subscribe(onNext: { [weak self] _ in
                self?.startPoll = ()
            }).disposed(by: disposeBag)

        model.killCoolTime
            .subscribe(onNext: { [weak self] time in
                if self?.isKilled ?? true {
                    return
                }
                self?.killCoolTime = time
            }).disposed(by: disposeBag)

        model.resultDecided
            .subscribe(onNext: { [weak self] winnerRole in
                self?.winnerRole = winnerRole
            }).disposed(by: disposeBag)

        showMyQRCodeRelay
            .subscribe { [weak self] string in
                self?.showMyQRCode = string
            }.disposed(by: disposeBag)
    }

    func didTapKillButton() {
        if isKilled {
            return
        }
        model.kill().subscribe(onSuccess: { [weak self] crewmate in
            self?.killedCrewmate = crewmate
        }).disposed(by: disposeBag)
    }

    func sabotage() {
        model.sabotage().subscribe().disposed(by: disposeBag)
    }

    func didTapSabotageButton() {
        fatalError("sabotageタスクの内容を考える")
    }

    func didTapShowMyQRCode() {
        guard let qrCode = model.me?.qrCode else {
            return
        }
        showMyQRCodeRelay.accept(qrCode)
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
        model.report()
            .subscribe()
            .disposed(by: disposeBag)
    }
}
