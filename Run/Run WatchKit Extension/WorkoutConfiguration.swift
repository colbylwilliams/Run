//
//  WorkoutConfiguration.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/31/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation

class WorkoutConfiguration {
    
    fileprivate(set) var workoutDurationMinutes: Int = 0
    
    var workoutDurationSeconds: Double { return Double (workoutDurationMinutes * 60) }

    func setWorkoutDuration(hours: Int, minutes: Int) {
        workoutDurationMinutes = (hours * 60) + minutes
    }

    var workoutTime: (hours:Int, minutes:Int) {
        return (workoutDurationMinutes / 60, workoutDurationMinutes % 60)
    }

    var targetHeartRate: Double?
}
