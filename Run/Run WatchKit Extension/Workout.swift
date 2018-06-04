//
//  Workout.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 6/3/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import HealthKit


enum WorkoutType {
    case timed
    case interval
}

struct WorkoutUnits {
    static let heartRateUnit = HKUnit(from: "count/min")
    static let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
}

protocol Workout {
    
    var duration: TimeInterval { get }
    
    var runningDates: [DateInterval] { get }
    
    func addRunningDates (start: Date, end: Date)
}


extension Workout {
    
    func duration (in unit: UnitDuration) -> Measurement<UnitDuration> {
        return Measurement(value: duration, unit: unit)
    }
    
    func durationComponents () -> (hours:Int, minutes:Int, seconds:Int) {
        return (Int(duration / 3600), Int(duration.truncatingRemainder(dividingBy: 3600) / 60), Int(duration.truncatingRemainder(dividingBy: 60)))
    }
    
    
    func durationCompleted () -> TimeInterval {
        return self.runningDates.reduce(0) { $0 + $1.duration }
    }
    
    func durationCompleted (in unit: UnitDuration) -> Measurement<UnitDuration> {
        return Measurement(value: durationCompleted(), unit: unit)
    }
    
    
    func durationRemaining () -> TimeInterval {
        return self.duration - durationCompleted()
    }
    
    func durations () -> (total: TimeInterval, completed: TimeInterval, remaining: TimeInterval) {
        let completed = durationCompleted()
        return (total: duration, completed: completed, remaining: duration - completed)
    }
}

class WorkoutInterval: Workout {

    fileprivate(set) var duration: TimeInterval = 0
    
    fileprivate(set) var runningDates: [DateInterval] = []
    
    var pace: Double = 0
    
    var incline: Double = 0
    
    var heartRate: HeartRate = 0
    
    init(pace: Double, incline: Double) {
        self.pace = pace
        self.incline = incline
    }

    init(pace: Double, incline: Double, minutes: Double) {
        self.pace = pace
        self.incline = incline
        self.duration = minutes * 60
    }

    init(pace: Double, incline: Double, hours: Int, minutes: Int, seconds: Int) {
        self.pace = pace
        self.incline = incline
        self.duration = TimeInterval((hours * 3600) + (minutes * 60) + seconds)
    }
}


extension WorkoutInterval {
    
    func setDuration (hours: Int, minutes: Int, seconds: Int) {
        duration = TimeInterval((hours * 3600) + (minutes * 60) + seconds)
    }
    
    func addRunningDates (start: Date, end: Date) {
        guard end >= start else { return }
        runningDates.append(DateInterval(start: start, end: end))
    }

    func pace (in unit: UnitSpeed) -> Measurement<UnitSpeed> {
        return Measurement(value: pace, unit: unit)
    }
}


class TimedWorkout: WorkoutInterval {
    
}


class IntervalWorkout: Workout {
    
    var count: Int = 0
    
    var duration: TimeInterval {
        return (intensityInterval.duration * Double(count)) + (recoveryInterval.duration * Double(count))
    }
    
    var runningDates: [DateInterval] {
        return (intensityInterval.runningDates + recoveryInterval.runningDates).sorted { $0.start < $1.start }
    }
    
    var intensityInterval: WorkoutInterval!
    
    var recoveryInterval: WorkoutInterval!
    
    
    init(intensity: WorkoutInterval, recovery: WorkoutInterval) {
        
    }
    
    
    func addRunningDates (start: Date, end: Date) {
        guard end >= start else { return }
        //runningDates.append(DateInterval(start: start, end: end))
    }
}


enum WorkoutIntervalType {
    case warmUp
    case recovery
    case highIntensity
}




typealias HeartRate = Double

