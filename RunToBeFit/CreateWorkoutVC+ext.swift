//
//  CreateWorkoutVC+ext.swift
//  RunToBeFit
//
//  Created by krAyon on 26.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import UIKit
import CoreLocation

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
    
    func presentPermissionErrorAlert() {
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
    
    func stringFromTime(timeInterval: TimeInterval) -> String {
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
}
