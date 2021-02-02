//
//  PlayerModel.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/20.
//

import CoreLocation
import RxRelay
import RxSwift

protocol PlayerModelType {
    associatedtype P: Player

    var meObservable: Observable<P> { get }
    var me: P? { get }

    var locationManager: CLLocationManager { get }
    var location: Observable<CLLocation?> { get }
    var impostors: Observable<[Impostor]> { get }
    var crewmates: Observable<[Crewmate]> { get }
    var didStartPoll: Observable<Void> { get }
    var isKilled: Observable<Bool> { get }
    var resultDecided: Observable<PlayerRole> { get }

    func report() -> Single<Void>
    func startEmergencyMeeting() -> Single<Void>
}

protocol ImpostorModelType: PlayerModelType {
    var killCoolTime: Observable<Int> { get }
    var sabotageCoolTime: Observable<Int> { get }
    var canKill: Observable<Bool> { get }
    func kill() -> Single<Crewmate>
    func sabotage() -> Single<Void>
}
