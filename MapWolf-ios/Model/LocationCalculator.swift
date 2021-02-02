//
//  LocationComparisonController.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/26.
//

import CoreLocation

struct LocationCalculator {
    func getDistanceByMeter(from first: PlayerLocation, to second: PlayerLocation) -> Double {
        let firstLocation = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let secondLocation = CLLocation(latitude: second.latitude, longitude: second.longitude)
        return firstLocation.distance(from: secondLocation)
    }

    func convert(_ coordinate: CLLocationCoordinate2D) -> PlayerLocation {
        .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
