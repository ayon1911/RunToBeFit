//
//  FirstViewController.swift
//  RunToBeFit
//
//  Created by krAyon on 25.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import UIKit
import CoreLocation

enum WorkoutState {
    case inactive
    case active
    case paused
}
let defaultTimeInterval: TimeInterval = 1.0

class CreateWorkoutVC: UIViewController {
    
    @IBOutlet weak var workoutTimeLbl: UILabel?
    @IBOutlet weak var workoutDistanceLbl: UILabel?
    @IBOutlet weak var toggleWorkoutBtn: UIButton?
    @IBOutlet weak var pauseWorkoutBtn: UIButton?
    
    var currentState = WorkoutState.inactive
    let locationManager = CLLocationManager()
    var lastSavedTime: Date?
    var workoutDuration: TimeInterval = 0.0
    var workoutTimer: Timer?
    var workoutDistance: Double = 0.0
    var lastSavedLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateUserInterface()
    }

    @IBAction func toggeleWorkout() {
        print("Toggle button was pressed")
        switch currentState {
        case .inactive:
            requestLocationPermssion()
        case .active:
            currentState = .inactive
            stopWorkoutTimer()
            WorkoutDataManager.shared.saveWorkout(duration: workoutDistance)
        default:
            print("toggle workout called out of context")
        }
        updateUserInterface()
    }
    @IBAction func pauseWorkout() {
        switch currentState {
        case .paused:
            startWorkout()
        case .active:
            currentState = .paused
            lastSavedTime = nil
            stopWorkoutTimer()
        default:
            print("Workout called out of context")
        }
        updateUserInterface()
    }
    
    fileprivate func updateUserInterface() {
        switch currentState {
        case .active:
            toggleWorkoutBtn?.setTitle("Stop", for: .normal)
            pauseWorkoutBtn?.setTitle("pause", for: .normal)
            pauseWorkoutBtn?.isHidden = false
        case .paused:
            pauseWorkoutBtn?.setTitle("Resume", for: .normal)
            pauseWorkoutBtn?.isHidden = false
        default:
            toggleWorkoutBtn?.setTitle("Start", for: .normal)
            pauseWorkoutBtn?.setTitle("Pause", for: .normal)
            pauseWorkoutBtn?.isHidden = true
        }
    }
    
    fileprivate func requestLocationPermssion() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 10.0
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.delegate = self
            
            switch (CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse:
                requestAlwaysPermission()
            case .authorizedAlways:
                lastSavedTime = Date()
                workoutDuration = 0.0
                workoutDistance = 0.0
                startWorkout()
            default:
                presentPermissionErrorAlert()
            }
            print("Location services are available")
        } else {
            presentPermissionErrorAlert()
        }
    }
    fileprivate func startWorkout() {
        print("Start workout")
        currentState = .active
        UserDefaults.standard.set(true, forKey: "isConfigured")
        UserDefaults.standard.synchronize()
        workoutTimer = Timer.scheduledTimer(timeInterval: defaultTimeInterval, target: self, selector: #selector(handleUpdateWorkoutData), userInfo: nil, repeats: true)
        lastSavedTime = Date()
        locationManager.startUpdatingLocation()
        WorkoutDataManager.shared.createWorkout()
    }
    fileprivate func requestAlwaysPermission() {
        if let isConfigured = UserDefaults.standard.value(forKey: "isConfigured") as? Bool, isConfigured == true {
            startWorkout()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    fileprivate func presentPermissionErrorAlert() {
        let alert = UIAlertController(title: "Permission Error", message: "Please enable location service on your device", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func stringFromTime(timeInterval: TimeInterval) -> String {
        let integerDuration = Int(timeInterval)
        let seconds = integerDuration % 60
        let minutes = (integerDuration / 60) % 60
        let hours = (integerDuration / 3600)
        if hours > 0 {
            return String("\(hours) hrs \(minutes) mins \(seconds) seconds")
        } else {
            print("Seconds : \(seconds)")
            return String("\(minutes) mins \(seconds) seconds")
        }
    }
    
    @objc fileprivate func handleUpdateWorkoutData() {
        let now = Date()
        if let lastTime = lastSavedTime {
            self.workoutDuration += now.timeIntervalSince(lastTime)
        }
        workoutTimeLbl?.text = stringFromTime(timeInterval: workoutDuration)
        workoutDistanceLbl?.text = String(format: "%.2f meters", arguments: [workoutDistance])
        lastSavedTime = now
    }
    
    fileprivate func stopWorkoutTimer() {
        workoutTimer?.invalidate()
    }
}

extension CreateWorkoutVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            requestAlwaysPermission()
        case .authorizedAlways:
            lastSavedTime = Date()
            workoutDuration = 0.0
            workoutDistance = 0.0
            startWorkout()
        case .denied:
            presentPermissionErrorAlert()
        default:
            NSLog("Unhandled Location Manager Status: \(status)")
        }
        print("Received permission change update!")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let mostRecentLocation = locations.last else {
            print("unable to read most recent location")
            return
        }
        if let savedLocation = lastSavedLocation {
            let distanceDelta = savedLocation.distance(from: mostRecentLocation)
            workoutDistance += distanceDelta
        }
        lastSavedLocation = mostRecentLocation
        print("Most recent location : \(mostRecentLocation)")
        WorkoutDataManager.shared.addLocation(coordinate: mostRecentLocation.coordinate)
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        NSLog("Location tracking paused")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        NSLog("Location tracking resumed")
    }
}
