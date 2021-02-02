//
//  CLLocationCoordinate2D+Extension.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/22.
//

import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
