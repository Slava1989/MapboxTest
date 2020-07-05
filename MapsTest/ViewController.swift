//
//  ViewController.swift
//  MapsTest
//
//  Created by Veaceslav Chirita on 7/5/20.
//  Copyright © 2020 Veaceslav Chirita. All rights reserved.
//

import UIKit
import Mapbox
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

class ViewController: UIViewController, MGLMapViewDelegate, NavigationViewControllerDelegate {
    var mapView: NavigationMapView!
    var navigationButton: UIButton!
    var currentLocation: CLLocationCoordinate2D!
    var originLocation: CLLocationCoordinate2D!
    var routeOptions: NavigationRouteOptions?
    var route: Route?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = NavigationMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(mapView)
        
        mapView.delegate = self
        
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
    }
    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        if originLocation == nil {
            originLocation = userLocation?.coordinate
        }
        currentLocation = userLocation?.coordinate
        calculateRoute(to: currentLocation)
    }
    
    func calculateRoute(to destination: CLLocationCoordinate2D) {
        let origin = Waypoint(coordinate: originLocation, coordinateAccuracy: -1, name: nil)
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: nil)
        let routeOptions = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .automobileAvoidingTraffic)
        
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let route = response.routes?.first, let self = self else {
                    return
                }
                
                self.route = route
                self.routeOptions = routeOptions
                
                self.drawRoute(route: route)
            }
        }
    }
    
    func drawRoute(route: Route) {
        guard let routeShape = route.shape, routeShape.coordinates.count > 0 else { return }
        
        var routeCoordinates = routeShape.coordinates
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: UInt(routeCoordinates.count))
        
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
            lineStyle.lineWidth = NSExpression(forConstantValue: 3)
            
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }
}
