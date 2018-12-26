//
//  SecondViewController.swift
//  RunToBeFit
//
//  Created by krAyon on 25.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import UIKit
import MapKit

class WorkoutMapVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView?.delegate = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showWorkout()
    }
    
    func showWorkout() {
        guard var locations = WorkoutDataManager.shared.getLastWorkout(), let first = locations.first, let last = locations.last else { return }
        let startPin = workoutAnnotations(title: "Start", coordinate: first)
        let endPin = workoutAnnotations(title: "End", coordinate: last)
        if let oldAnnotations = mapView?.annotations {
            mapView?.removeAnnotations(oldAnnotations)
        }
        mapView?.showAnnotations([startPin, endPin], animated: true)
        
        let workoutRoute = MKPolyline(coordinates: &locations, count: locations.count)
        mapView?.addOverlays([workoutRoute])
    }
    func workoutAnnotations(title: String, coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        return annotation
    }
}

extension WorkoutMapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let pathRenderer = MKPolylineRenderer(overlay: overlay)
        pathRenderer.strokeColor = UIColor.red
        pathRenderer.lineWidth = 3
        return pathRenderer
    }
}
