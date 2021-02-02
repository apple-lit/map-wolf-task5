//
//  LocationManager.swift
//  MapWolf-ios
//
//  Created by Fumiya Tanaka on 2021/01/22.
//

import CoreLocation
import RxRelay
import RxSwift

class LocationManager: CLLocationManager {
    let locationAuthorizationStatusRelay: PublishRelay<CLAuthorizationStatus> = .init()
    let locationRelay: BehaviorRelay<CLLocation?> = .init(value: nil)
    let inRegionRelay: PublishRelay<CLCircularRegion> = .init()

    override init() {
        super.init()
        delegate = self
        requestWhenInUseAuthorization()
        startUpdatingLocation()
    }

    func addRegionToMonitor(_ region: CLCircularRegion) {
        startMonitoring(for: region)
    }

    func removeAllRegionsForMonitor() {
        monitoredRegions.forEach { self.stopMonitoring(for: $0) }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        locationAuthorizationStatusRelay.accept(status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationRelay.accept(locations.last)
        manager.monitoredRegions.compactMap({ $0 as? CLCircularRegion }).forEach({ region in
            if let distance = manager.location?.distance(
                from: CLLocation(
                    latitude: region.center.latitude, longitude: region.center.longitude)) {
                if distance <= CrewmateMapConst.radius {
                    self.inRegionRelay.accept(region)
                }
            }
        })
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion, let location = manager.location {
            if region.contains(location.coordinate) {
                inRegionRelay.accept(region)
            }
        }
    }
}
