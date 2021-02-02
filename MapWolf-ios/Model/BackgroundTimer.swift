//
//  BackgroundTimer.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/30.
//

import Foundation
import RxRelay
import RxSwift

class BackgroundTimer {
    let notificationCenter: NotificationCenter = .default
    var timer: Timer = .init()
    let relay: BehaviorRelay<Int>
    let userDefaults: UserDefaults = .standard
    let initialTime: Int
    let disposeBag: DisposeBag = .init()

    init(initialTime: Int) {
        self.initialTime = initialTime
        relay = .init(value: initialTime)
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0, repeats: true,
            block: { _ in
                let current = self.relay.value
                self.relay.accept(current - 1)
            })

        notificationCenter.addObserver(forName: .didBecomeActive, object: nil, queue: .main) { _ in
            let willResignActiveAt = Date(
                timeIntervalSince1970: self.userDefaults.double(forKey: "willResignActive"))
            let diff = Int(Date().timeIntervalSince(willResignActiveAt))
            var calcTime = self.relay.value
            calcTime -= diff
            if calcTime < 0 {
                calcTime = 0
            }
            self.relay.accept(calcTime)
            self.startTimer(fromBeforeState: true)
        }

        notificationCenter.addObserver(forName: .willResignActive, object: nil, queue: .main) {
            [weak self] _ in
            self?.userDefaults.set(Date().timeIntervalSince1970, forKey: "willResignActive")
            self?.stopTimer()
        }

        relay.filter({ $0 <= 0 }).subscribe(onNext: { [weak self] _ in
            self?.stopTimer()
        }).disposed(by: disposeBag)
    }

    func stopTimer() {
        timer.invalidate()
    }

    func startTimer(fromBeforeState: Bool = false) {
        timer.invalidate()
        if !fromBeforeState {
            self.relay.accept(initialTime)
        }
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let time = self.relay.value
            self.relay.accept(time - 1)
        }
        self.timer = timer
    }
}
