//
//  MotionViewModel.swift
//  RunToBeFit
//
//  Created by krAyon on 26.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import Foundation
import CoreMotion

class MotionViewModel {
    
    var motionManager: CMMotionActivityManager?
    var currentWorkoutType = WorkoutType.unknown
        
    func startActivityUpdates() {
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
}
