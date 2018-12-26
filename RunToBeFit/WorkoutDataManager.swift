//
//  WorkoutDataManager.swift
//  RunToBeFit
//
//  Created by krAyon on 26.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import Foundation
import CoreLocation

struct Coordinate: Codable {
    var latitude: Double
    var logitude: Double
}
struct Workout: Codable {
    var endtime: Date
    var duration: TimeInterval
    var locations: [Coordinate]
}

typealias Workouts = [Workout]

class WorkoutDataManager {
    static let shared = WorkoutDataManager()
    private var workouts: Workouts?
    private var activeLocations: [CLLocationCoordinate2D]?
    
    private init() {
        loadFromPlist()
        print("Singleton Initialized")
    }
    
    private var workoutFileUrl: URL? {
        guard let documentsUrl = documentsDirectoruUrl() else { return nil }
        return documentsUrl.appendingPathComponent("Workout.plist")
    }
    
    func createWorkout() {
        activeLocations = [CLLocationCoordinate2D]()
    }
    func addLocation(coordinate: CLLocationCoordinate2D) {
        activeLocations?.append(coordinate)
    }
    
    func documentsDirectoruUrl() -> URL? {
      let filemanager = FileManager.default
        return filemanager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    //loading data from document directory of the app
    func loadFromPlist() {
        workouts = [Workout]()
        guard let fileUrl = workoutFileUrl else { return }
        print("file url: \(fileUrl.absoluteString)")
        do {
            let workoutData = try Data(contentsOf: fileUrl)
            let decoder = PropertyListDecoder()
            workouts = try decoder.decode(Workouts.self, from: workoutData)
        } catch {
            print("Error reading plist")
        }
    }
    //saving data from document directory
    func saveToPlist() {
        guard let fileUrl = workoutFileUrl else { return }
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let workoutData = try encoder.encode(workouts)
            try workoutData.write(to: fileUrl)
            print("File Saved to : \(fileUrl.absoluteString)")
        } catch {
            print("Error while writing to plist")
        }
    }
    //save workout for a duration
    func saveWorkout(duration: TimeInterval) {
        guard let activelocations = activeLocations else { return }
        let mappedCoordinates = activelocations.map { (value: CLLocationCoordinate2D) in
            return Coordinate(latitude: value.latitude, logitude: value.longitude)
        }
        let currentWorkout = Workout(endtime: Date(), duration: duration, locations: mappedCoordinates)
        workouts?.append(currentWorkout)
        saveToPlist()
    }
    //get the last saved workout
    func getLastWorkout() -> [CLLocationCoordinate2D]? {
        guard let workouts = workouts, let lastWorkout = workouts.last else { return nil }
        let locations = lastWorkout.locations.map { (value: Coordinate) in
            return CLLocationCoordinate2D(latitude: value.latitude, longitude: value.logitude)
        }
        return locations
    }
}
