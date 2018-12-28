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

    let locationManager = CLLocationManager()
    var lastSavedLocation: CLLocation?
    
    var isMotionAvailable: Bool = false
    
    let altMeterViewModel = AltitudeViewModel()
    let pedometerViewModel = PedometerViewModel()
    let motionViewModel = MotionViewModel()

    
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
            pedometerViewModel.pedometer?.stopUpdates()
            motionViewModel.startActivityUpdates()
            altMeterViewModel.altimeter?.stopRelativeAltitudeUpdates()
            if let workoutStartTime = workoutStartTime {
                let workout = Workout(startTime: workoutStartTime, endtime: Date(), duration: workoutDuration, locations: [], workoutTypes: motionViewModel.currentWorkoutType, totalSteps: pedometerViewModel.workoutSteps, flightsClimbed: pedometerViewModel.floorsAscended, distance: pedometerViewModel.workoutDistance)
                WorkoutDataManager.shared.saveWorkout(workout)
            }
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
    func startWorkout() {
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
            pedometerViewModel.startPedometerUpdates(with: lastSavedTime)
            motionViewModel.startActivityUpdates()
            altMeterViewModel.startAltmeterUpdates()
        } else {
            print("Motion activity not available on the device")
            isMotionAvailable = false
        }
    }
    func requestAlwaysPermission() {
        if let isConfigured = UserDefaults.standard.value(forKey: "isConfigured") as? Bool, isConfigured == true {
            startWorkout()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }

    @objc fileprivate func handleUpdateWorkoutData() {
        let now = Date()
        var workoutPaceText = String(format: "%.2f m/s |  %0.2fm ", arguments: [pedometerViewModel.averagePace, altMeterViewModel.workoutAltitude])
        
        if let lastTime = lastSavedTime {
            self.workoutDuration += now.timeIntervalSince(lastTime)
        }
        if motionViewModel.currentWorkoutType != WorkoutType.unknown {
            workoutPaceText.append(" | \(motionViewModel.currentWorkoutType)")
        }
        workoutTimeLbl?.text = stringFromTime(timeInterval: workoutDuration)
        workoutPaceLbl?.text = workoutPaceText
        workoutDistanceLbl?.text = String(format: "%.2fm | %d steps | %d floors", arguments: [pedometerViewModel.workoutDistance, pedometerViewModel.workoutSteps, pedometerViewModel.floorsAscended])
        
        lastSavedTime = now
    }
    
    fileprivate func stopWorkoutTimer() {
        workoutTimer?.invalidate()
    }
    
    func resetWorkoutData() {
        lastSavedTime = Date()
        workoutDuration = 0.0
        workoutDistance = 0.0
        pedometerViewModel.resetPedometerData()
        altMeterViewModel.workoutAltitude = 0.0
        motionViewModel.currentWorkoutType = WorkoutType.unknown
    }
}


