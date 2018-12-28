//
//  WorkoutViewModel.swift
//  RunToBeFit
//
//  Created by krAyon on 26.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import Foundation
import CoreMotion

class PedometerViewModel {
    
    var pedometer: CMPedometer?
    var averagePace: Double = 0.0
    var workoutSteps: Double = 0
    var floorsAscended: Double = 0
    var workoutDistance: Double = 0.0
    
    func startPedometerUpdates(with lastSavedDate: Date?) {
        guard let lastSavedTime = lastSavedDate else { return }
        pedometer = CMPedometer()
        pedometer?.startUpdates(from: lastSavedTime, withHandler: { [weak self] (pedometerData, error) in
            //update pedometer data
            if let err = error {
                print("Could not measure pedometer data", err)
            }
            self?.getPedometerData(from: pedometerData)
        })
    }
    
    func getPedometerData(from pedometerData: CMPedometerData?) {
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
    
    func resetPedometerData() {
        workoutSteps = 0
        floorsAscended = 0
        averagePace = 0.0
    }
}
