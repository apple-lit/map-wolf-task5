//
//  MapView.swift
//  MapWolf-ios
//
//  Created by 張翔 on 2021/01/25.
//

import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var spotTasks: [SpotTask]
    let avatar: Avatar
    let center: CLLocationCoordinate2D
    let emergencyPoint: CLLocationCoordinate2D

    func makeCoordinator() -> Coordinator {
        return Coordinator(avatar: avatar)
    }

    typealias UIViewType = MKMapView

    func makeUIView(context: Context) -> MKMapView {
        let mkMapView = MKMapView(frame: .zero)
        mkMapView.delegate = context.coordinator

        mkMapView.showsUserLocation = true

        let circle = MKCircle(center: center, radius: 500)
        mkMapView.addOverlay(circle)

        let region = MKCoordinateRegion(
            center: center, span: .init(latitudeDelta: 0.015, longitudeDelta: 0.015))
        mkMapView.region = region

        return mkMapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)

        let emergencyAnnotation = MKPointAnnotation()
        emergencyAnnotation.coordinate = emergencyPoint
        uiView.addAnnotation(emergencyAnnotation)

        spotTasks.forEach { spotTask in
            let annotation = TaskAnnotation(spotTask: spotTask)
            uiView.addAnnotation(annotation)
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let avatar: Avatar

        init(avatar: Avatar) {
            self.avatar = avatar
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.strokeColor = Asset.Colors.mwPink.color
            circleRenderer.fillColor = Asset.Colors.mwPink.color.withAlphaComponent(0.52)
            circleRenderer.lineWidth = 2
            return circleRenderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            func createCircleView(color: UIColor) -> UIView {
                let view = UIView(frame: CGRect(x: -25, y: -25, width: 50, height: 50))
                view.backgroundColor = color
                view.layer.cornerRadius = view.frame.width / 2
                view.clipsToBounds = true
                return view
            }

            if annotation.isEqual(mapView.userLocation) {
                let annotationView = MKAnnotationView(
                    annotation: annotation, reuseIdentifier: "userLocation")
                annotationView.image =
                    avatar.resourceName.emojiToImage(size: 50)
                    ?? Avatar.defaultAvatar.resourceName.emojiToImage(size: 50)
                return annotationView
            } else if let annotation = annotation as? TaskAnnotation {
                let annotationView = MKAnnotationView(
                    annotation: annotation, reuseIdentifier: "task")
                let circleView = createCircleView(color: annotation.color)
                annotationView.addSubview(circleView)
                return annotationView
            } else if let annotation = annotation as? MKPointAnnotation {
                let annotationView = MKAnnotationView(
                    annotation: annotation, reuseIdentifier: "emergency")
                annotationView.image = "🚨".emojiToImage(size: 50)
                return annotationView
            }
            return nil
        }
    }

    class TaskAnnotation: NSObject, MKAnnotation {
        private var spotTask: SpotTask

        init(spotTask: SpotTask) {
            self.spotTask = spotTask
        }

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: spotTask.latitude, longitude: spotTask.longitude)
        }

        var color: UIColor {
            UIColor(hex: spotTask.colorHex)
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(
            spotTasks: .constant([]), avatar: .defaultAvatar,
            center: CLLocationCoordinate2D(latitude: 35.6809591, longitude: 139.7673068),
            emergencyPoint: Constant.emergencyPoint)
    }
}
