//
//  NotificationName+Extension.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/27.
//

import Foundation

extension Notification.Name {
    static let willResignActive: Notification.Name = .init("willResignActive")
    static let didBecomeActive: Notification.Name = Notification.Name("didBecomeActive")
}
