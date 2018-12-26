//
//  FirstViewController.swift
//  RunToBeFit
//
//  Created by krAyon on 25.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion

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
    @IBOutlet weak var workoutPaceLbl: UILabel!
    
    var currentState = WorkoutState.inactive
    
    var lastSavedTime: Date?
    var workoutDuration: TimeInterval = 0.0
    var workoutTimer: Timer?
    var workoutDistance: Double = 0.0
    
    var workoutStartTime: Date?
    var pedometer: CMPedometer?
    var averagePace: Double = 0.0
    var workoutSteps: Double = 0
    var floorsAscended: Double = 0
    
    var motionManager: CMMotionActivityManager?
    var currentWorkoutType = WorkoutType.unknown
    
    let locationManager = CLLocationManager()
    var lastSavedLocation: CLLocation?
    
    var isMotionAvailable: Bool = false
    
    let altMeterViewModel = AltitudeViewModel()
//    var workoutAltitude: Double = 0.0
//    var altimeter: CMAltimeter?
    
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
            pedometer?.stopUpdates()
            motionManager?.stopActivityUpdates()
            altMeterViewModel.altimeter?.stopRelativeAltitudeUpdates()
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
                resetWorkoutData()
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
        workoutStartTime = Date()
        locationManager.startUpdatingLocation()
        WorkoutDataManager.shared.createWorkout()
        //checing if Motion, Pedometer, Altitude meter is available
        if (CMMotionManager().isDeviceMotionAvailable && CMPedometer.isStepCountingAvailable() && CMAltimeter.isRelativeAltitudeAvailable()) {
            //start motion updates
            isMotionAvailable = true
            startPedometerUpdates()
            startActivityUpdates()
            altMeterViewModel.startAltmeterUpdates()
        } else {
            print("Motion activity not available on the device")
            isMotionAvailable = false
        }
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
        var workoutPaceText = String(format: "%.2f m/s |  %0.2fm ", arguments: [averagePace, altMeterViewModel.workoutAltitude])
        
        if let lastTime = lastSavedTime {
            self.workoutDuration += now.timeIntervalSince(lastTime)
        }
        if currentWorkoutType != WorkoutType.unknown {
            workoutPaceText.append(" | \(currentWorkoutType)")
        }
        workoutTimeLbl?.text = stringFromTime(timeInterval: workoutDuration)
        workoutPaceLbl?.text = workoutPaceText
        workoutDistanceLbl?.text = String(format: "%.2fm | %d steps | %d floors", arguments: [workoutDistance, workoutSteps, floorsAscended])
        
        lastSavedTime = now
    }
    
    fileprivate func stopWorkoutTimer() {
        workoutTimer?.invalidate()
    }
    
    fileprivate func startPedometerUpdates() {
        guard let lastSavedTime = lastSavedTime else { return }
        pedometer = CMPedometer()
        pedometer?.startUpdates(from: lastSavedTime, withHandler: { [weak self] (pedometerData, error) in
            //update pedometer data
            if let err = error {
                print("Could not measure pedometer data", err)
            }
            self?.getPedometerData(from: pedometerData)
        })
    }
    
    fileprivate func getPedometerData(from pedometerData: CMPedometerData?) {
        guard let pedometerData = pedometerData,
            let distance = pedometerData.distance as? Double,
            let pace = pedometerData.averageActivePace as? Double,
            let steps = pedometerData.numberOfSteps as? Int,
            let floor = pedometerData.floorsAscended as? Int else { return }
        workoutDistance = distance
        workoutSteps = Double(steps)
        floorsAscended = Double(floor)
        averagePace = pace
    }
    
    fileprivate func resetWorkoutData() {
        lastSavedTime = Date()
        workoutDuration = 0.0
        workoutDistance = 0.0
        workoutSteps = 0
        floorsAscended = 0
        averagePace = 0.0
        altMeterViewModel.workoutAltitude = 0.0
        currentWorkoutType = WorkoutType.unknown
    }
    
    fileprivate func startActivityUpdates() {
        motionManager = CMMotionActivityManager()
        motionManager?.startActivityUpdates(to: OperationQueue.main, withHandler: { [weak self] (activity: CMMotionActivity?) in
            //received motion update
            guard let activity = activity else { return }
            if activity.walking {
                self?.currentWorkoutType = WorkoutType.walking
            } else if activity.running {
                self?.currentWorkoutType = WorkoutType.running
            } else if activity.cycling {
                self?.currentWorkoutType = WorkoutType.bicycling
            } else if activity.stationary {
                self?.currentWorkoutType = WorkoutType.stationary
            } else {
                self?.currentWorkoutType = WorkoutType.unknown
            }
        })
    }
    
//    fileprivate func startAltmeterUpdates() {
//        altimeter = CMAltimeter()
//        altimeter?.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { [weak self] (altmeterData: CMAltitudeData?, error: Error?) in
//            if let err = error {
//                print("An error occured while fetching Altitude Data", err)
//                return
//            }
//            guard let altitudeData = altmeterData else { return }
//            guard let relativeAltitude = altitudeData.relativeAltitude as? Double else { return }
//            self?.workoutAltitude = relativeAltitude
//        })
//    }
}

extension CreateWorkoutVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            requestAlwaysPermission()
        case .authorizedAlways:
            resetWorkoutData()
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
