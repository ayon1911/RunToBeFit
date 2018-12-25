//
//  FirstViewController.swift
//  RunToBeFit
//
//  Created by krAyon on 25.12.18.
//  Copyright © 2018 DocDevs. All rights reserved.
//

import UIKit

class CreateWorkoutVC: UIViewController {
    
    @IBOutlet weak var workoutTimeLbl: UILabel?
    @IBOutlet weak var workoutDistanceLbl: UILabel?
    @IBOutlet weak var toggleWorkoutBtn: UIButton?
    @IBOutlet weak var pauseWorkoutBtn: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func toggeleWorkout() {
        NSLog("Toggle workout button pressed")
    }
    @IBAction func pauseWorkout() {
        NSLog("Pause button pressed")
    }
}

