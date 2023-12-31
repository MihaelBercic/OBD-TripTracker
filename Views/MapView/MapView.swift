//
//  MapView.swift
//  CarInfo
//
//  Created by Mihael Bercic on 09/07/2023.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    
    private let path = [CLLocation(latitude: 46.02550, longitude: 14.54126),
                        CLLocation(latitude: 46.02531, longitude: 14.54096),
                        CLLocation(latitude: 46.02504, longitude: 14.54070),
                        CLLocation(latitude: 46.02489, longitude: 14.54038),
                        CLLocation(latitude: 46.02467, longitude: 14.54008),
                        CLLocation(latitude: 46.02450, longitude: 14.53948)]
    
    @Binding var currentTrips: [TripEntity]
    
    func makeCoordinator() -> MapViewDelegate {
        return MapViewDelegate()
    }
    
    func updateUIView(_ x: UIViewType, context: Context) {
        guard let mapView = x as? MKMapView else { return }
        let delegate = context.coordinator
        mapView.delegate = delegate
        // delegate.setCurrentTrip(mapView: mapView, currentTrip)
        delegate.setCurrentTrips(mapView: mapView, trips: currentTrips)
    }
    
    func makeUIView(context _: Context) -> some UIView {
        let mapView = MKMapView()
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .default)
        mapView.showsCompass = false
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .excludingAll
        // mapView.isPitchEnabled = false
        return mapView
    }
    
}

class MapViewDelegate: NSObject, MKMapViewDelegate {
    
    private(set) var currentTrips: [TripEntity] = []
    private(set) var mapView: MKMapView? = nil
    
    private var animationTimer: Timer? = nil
    private var newRenderNeeded: Bool = false
    private var canRender: Bool = false
    private var currentTimer: Timer? = nil
    private var canRenderSpeed: Bool = false
    
    private var totalPolyline: MKPolyline? = nil
    private var tripOverlays: [TripOverlay] = []
    private var renderers: [MyRenderer] = []
    
    func setCurrentTrips(mapView:MKMapView, trips: [TripEntity]) {
        self.mapView = mapView
        if currentTrips != trips {
            newRenderNeeded = true
            currentTrips = trips
            currentTimer?.invalidate()
            tripOverlays = trips.filter{$0.locations.count > 0}.map { trip in
                let path = trip.locations.map { coordinate in
                    let latitude = coordinate.latitude.doubleValue
                    let longitude = coordinate.longitude.doubleValue
                    let speed = coordinate.speed
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let altitude = CLLocationDistance()
                    return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: CLLocationAccuracy(), verticalAccuracy: CLLocationAccuracy(), course: 0.0, speed: Double(speed), timestamp: .now)
                }
                return TripOverlay(path: path)
            }
            
            if !tripOverlays.isEmpty {
                animateTrip(mapView: mapView)
            } else {
                mapView.removeOverlays(mapView.overlays)
            }
        }
    }
    
    private func animateTrip(mapView: MKMapView) {
        let coordinates = tripOverlays.flatMap {$0.coordinates}
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        totalPolyline = polyline
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 200.0, left: 50.0, bottom: 300.0, right: 50.0), animated: true)
    }
    
    func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        currentScale = .zero
        guard let totalPolyline = totalPolyline else { return }
        let scale = totalPolyline.boundingMapRect.width / mapView.visibleMapRect.width * minZoomScale
        let decidedScale = min(maxZoomScale, max(minZoomScale, scale))
        renderers.forEach { renderer in
            renderer.scale = decidedScale
            renderer.setNeedsDisplay()
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated _: Bool) {
        if newRenderNeeded {
            renderers = []
            newRenderNeeded = false
            canRenderSpeed = false
            
            mapView.removeOverlays(mapView.overlays)
            let shouldDisplaySpeed = tripOverlays.count < 10
            tripOverlays.forEach { tripOverlay in
                DispatchQueue.main.async { [self] in
                    let path = tripOverlay.path
                    let coordinates = tripOverlay.coordinates
                    let segmentSize = max(1, coordinates.count / 25)
                    var previousPolyline: MKPolyline? = nil
                    var currentSegment = 1
                    var colorName = "RouteNormal"

                    if !shouldDisplaySpeed {
                        let coordinates = tripOverlay.coordinates
                        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                        let border = MKPolyline(coordinates: coordinates, count: coordinates.count)
                        polyline.subtitle = colorName
                        border.subtitle = colorName
                        border.title = "border"
                        mapView.addOverlays([border, polyline], level: .aboveLabels)
                    } else {
                        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [self] timer in
                            let currentMaxIndex = min(coordinates.count - 1, currentSegment * segmentSize)
                            let minimumIndex = max(currentMaxIndex - segmentSize - 1, 0)
                            let isLastSegment = currentMaxIndex >= coordinates.count - 1
                            let segment = Array(path[minimumIndex ... currentMaxIndex])
                            let averageSpeed = segment.reduce(0.0) { $0 + $1.speed } / Double(segment.count) * 3.6
                            
                            if averageSpeed == 0.0 {
                               colorName = "RouteStop"
                            } else if averageSpeed <= 15 {
                                colorName = "RouteSuperSlow"
                            } else if averageSpeed <= 30 {
                                colorName = "RouteSlow"
                            } else if averageSpeed <= 60 {
                                colorName = "RouteMedium"
                            } else if averageSpeed <= 90 {
                                colorName = "RouteFast"
                            } else {
                                colorName = "RouteSuperFast"
                            }
                            let cleanedCoordinates = segment.map { $0.coordinate }
                            let polyline = MKPolyline(coordinates: cleanedCoordinates, count: cleanedCoordinates.count)
                            let border = MKPolyline(coordinates: cleanedCoordinates, count: cleanedCoordinates.count)
                            
                            border.title = "border"
                            polyline.subtitle = colorName
                            border.subtitle = colorName
                            if let previousPolyline = previousPolyline {
                                mapView.insertOverlay(border, below: previousPolyline)
                                mapView.insertOverlay(polyline, above: previousPolyline)
                            } else {
                                mapView.addOverlays([border, polyline], level: .aboveLabels)
                            }
                            previousPolyline = polyline
                            currentSegment += 1
                            if isLastSegment {
                                timer.invalidate()
                            }
                        }
                    }
                }
            }
            
            
            
            
            
        }
    }
    
    func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer()
        }
        
        let percentageChange = 15.0
        let isBorder = polyline.title == "border"
        let isLightMode = UIScreen.main.traitCollection.userInterfaceStyle == .light
        let currentColor = UIColor(named: polyline.subtitle!)!
        let renderer = MyRenderer(polyline: polyline).apply {
            $0.lineWidth = isBorder ? 2.5 : 1.5
            $0.strokeColor = isBorder ? (isLightMode ? currentColor.darker(by: percentageChange) : currentColor.lighter(by: percentageChange)) : currentColor
            $0.lineCap = .round
        }
        renderers.append(renderer)
        return renderer
    }
    
}

let minZoomScale: MKZoomScale = 0.001
let maxZoomScale: MKZoomScale = 0.1
var currentScale: CGFloat = .zero

class MyRenderer: MKPolylineRenderer {
    
    var scale: CGFloat? = nil
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let decidedScale = min(maxZoomScale, max(minZoomScale, zoomScale))
        if decidedScale >= currentScale {
            currentScale = decidedScale
        }
        super.draw(mapRect, zoomScale: currentScale, in: context)
    }
}

struct MapView_Previews: PreviewProvider {
    
    @State static var currentTrip: TripEntity? = TripEntity(context: CoreDataManager.shared.viewContext).apply { entity in
        entity.start = .now
        entity.end = .now
        entity.timestamp = .now
        [
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02550, longitude: 14.54126), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 10.0, timestamp: .now),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02531, longitude: 14.54096), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 30.0, timestamp: .now),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02504, longitude: 14.54070), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 50.0, timestamp: .now),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02489, longitude: 14.54038), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 23.0, timestamp: .now),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02467, longitude: 14.54008), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 100.0, timestamp: .now),
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: 46.02450, longitude: 14.53948), altitude: 0.0, horizontalAccuracy: 0.0, verticalAccuracy: 0.0, course: 0.0, speed: 5.0, timestamp: .now),
        ].map { location in
            CoordinateEntity(context: CoreDataManager.shared.viewContext).apply {
                $0.latitude = location.coordinate.latitude.asDecimal
                $0.longitude = location.coordinate.longitude.asDecimal
                $0.speed = Int16(location.speed.rounded())
            }
        }
        .forEach { coord in
            entity.addToLocations(coord)
        }
    }
    
    @State static var currentTrips: [TripEntity] = [currentTrip!, currentTrip!]
    
    static var previews: some View {
        MapView(currentTrips: $currentTrips)
    }
}

class TripOverlay {
    
    let path: [CLLocation]
    let polyline: MKPolyline
    let coordinates: [CLLocationCoordinate2D]
    
    init(path: [CLLocation]) {
        self.path = path
        self.coordinates = path.map {$0.coordinate}
        self.polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}
