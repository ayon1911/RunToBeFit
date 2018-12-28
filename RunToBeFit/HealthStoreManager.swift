//
//  HealthStoreManager.swift
//  RunToBeFit
//
//  Created by krAyon on 28.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import Foundation
import HealthKit

class HealthStoreManager {
    
    static let shared = HealthStoreManager()
    private var healthStore: HKHealthStore?

    init() {
        print("Health kit is initialized")
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore.init()
        }
    }
    
    private var hkDataTypes: Set<HKSampleType> {
        var hkTypeSet = Set<HKSampleType>()
        if let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            hkTypeSet.insert(stepCountType)
        }
        if let flightClimedType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            hkTypeSet.insert(flightClimedType)
        }
        if let cyclingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceCycling) {
            hkTypeSet.insert(cyclingDistanceType)
        }
        if let walkingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            hkTypeSet.insert(walkingDistanceType)
        }
        hkTypeSet.insert(HKObjectType.workoutType())
        return hkTypeSet
    }
    
    func saveWorkoutToHealthKit(_ workout: Workout) {
        healthStore?.requestAuthorization(toShare: hkDataTypes, read: hkDataTypes, completion: { [weak self] (isAuthorized: Bool, error: Error?) in
            //Request completed, it is now safe to use HealthKit..
            if let error = error {
                print("Error accessing HealthKit: \(error.localizedDescription)")
            } else {
                guard let workoutObject = self?.createHKWorkout(workout) else { return }
                self?.healthStore?.save(workoutObject, withCompletion: { (success, error) in
                    if let err = error {
                        print("Error creating workout object:", err)
                    } else {
                        //add sample workout data
                        self?.addSamples(hkWorkout: workoutObject, workingData: workout)
                    }
                })
            }
        })
    }
    
    func loadWorkoutFromHealthKit() {
        healthStore?.requestAuthorization(toShare: hkDataTypes, read: hkDataTypes, completion: { (isAuthorized: Bool, error: Error?) in
            //Request completed, it is now safe to use HealthKit..
        })
    }
    
    func createHKWorkout(_ workout: Workout) -> HKWorkout? {
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: workout.distance)
        var activityType = HKWorkoutActivityType.walking
        
        switch(workout.workoutTypes) {
        case WorkoutType.running:
            activityType = HKWorkoutActivityType.running
        case WorkoutType.bicycling:
            activityType = HKWorkoutActivityType.cycling
        default:
            activityType = HKWorkoutActivityType.walking
        }
        return HKWorkout(activityType: activityType, start: workout.startTime, end: workout.endtime, duration: workout.duration, totalEnergyBurned: nil, totalDistance: distanceQuantity, device: nil, metadata: nil)
    }
    
    func addSamples(hkWorkout: HKWorkout, workingData: Workout) {
        var samples = [HKSample]()
        addStepCountSample(workingData, objectArray: &samples)
        addFlightsClimedSample(workingData, objectArray: &samples)
        addDistanceSample(workingData, activityType: hkWorkout.workoutActivityType, objectArray: &samples)
        self.healthStore?.add(samples, to: hkWorkout, completion: { (success, error) in
            if let saveError = error {
                print("Error adding workout samples", saveError.localizedDescription)
            } else {
                print("workout samples added successfully")
            }
        })
    }
    func addStepCountSample(_ workoutData: Workout, objectArray: inout [HKSample]) {
        guard let stepQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let stepUnit = HKUnit.count()
        let stepQuantity = HKQuantity(unit: stepUnit, doubleValue: workoutData.totalSteps)
        let stepSample = HKQuantitySample(type: stepQuantityType, quantity: stepQuantity, start: workoutData.startTime, end: workoutData.endtime)
        objectArray.append(stepSample)
    }
    func addFlightsClimedSample(_ workoutData: Workout, objectArray: inout [HKSample]) {
        guard let flightQuantityType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return }
        let flightUnit = HKUnit.count()
        let flightQuantity = HKQuantity(unit: flightUnit, doubleValue: workoutData.flightsClimbed)
        let flightSample = HKQuantitySample(type: flightQuantityType, quantity: flightQuantity, start: workoutData.startTime, end: workoutData.endtime)
        objectArray.append(flightSample)
    }
    func addDistanceSample(_ workoutData: Workout, activityType: HKWorkoutActivityType, objectArray: inout [HKSample]) {
        guard let cyclingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceCycling),
            let walkingDistanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
            else { return }
        let distanceUnit = HKUnit.meter()
        let distanceQuantity = HKQuantity(unit: distanceUnit, doubleValue: workoutData.distance)
        let distanceQuantityType = activityType == HKWorkoutActivityType.cycling ? cyclingDistanceType : walkingDistanceType
        let distanceSample = HKQuantitySample(type: distanceQuantityType, quantity: distanceQuantity, start: workoutData.startTime, end: workoutData.endtime)
        objectArray.append(distanceSample)
        
    }
}
