//
//  AltitudeViewModel.swift
//  RunToBeFit
//
//  Created by krAyon on 26.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import Foundation
import CoreMotion

class AltitudeViewModel {
    
    var workoutAltitude: Double = 0.0
    var altimeter: CMAltimeter?
    
    func startAltmeterUpdates() {
        altimeter = CMAltimeter()
        altimeter?.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { [weak self] (altmeterData: CMAltitudeData?, error: Error?) in
            if let err = error {
                print("An error occured while fetching Altitude Data", err)
                return
            }
            guard let altitudeData = altmeterData else { return }
            guard let relativeAltitude = altitudeData.relativeAltitude as? Double else { return }
            self?.workoutAltitude = relativeAltitude
        })
    }
}
