//
//  Run.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 6/3/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import HealthKit


enum RunType {
    case timed
    case interval
}

protocol Run {
    
    var duration: TimeInterval { get }
}


extension Run {
    
    func duration (in unit: UnitDuration) -> Measurement<UnitDuration> {
        return Measurement(value: duration, unit: unit)
    }
    
    func durationComponents () -> (hours:Int, minutes:Int, seconds:Int) {
        return (Int(duration / 3600), Int(duration.truncatingRemainder(dividingBy: 3600) / 60), Int(duration.truncatingRemainder(dividingBy: 60)))
    }
}


class RunInterval: Run {

    fileprivate(set) var duration: TimeInterval = 0
    
    fileprivate(set) var activityIntervals: [DateInterval] = []
    
    var pace: Double = 0
    
    var incline: Double = 0
    
    var heartRate: Double = 0
    
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


extension RunInterval {
    
    func setDuration (hours: Int, minutes: Int, seconds: Int) {
        duration = TimeInterval((hours * 3600) + (minutes * 60) + seconds)
    }
    
    func pace (in unit: UnitSpeed) -> Measurement<UnitSpeed> {
        return Measurement(value: pace, unit: unit)
    }
}


class TimedRun: RunInterval {
    
}


class IntervalRun: Run {
    
    var count: Int = 0
    
    var duration: TimeInterval {
        return (intensityInterval.duration * Double(count)) + (recoveryInterval.duration * Double(count))
    }
    
    var activityIntervals: [DateInterval] {
        return (intensityInterval.activityIntervals + recoveryInterval.activityIntervals).sorted { $0.start < $1.start }
    }
    
    var intensityInterval: RunInterval!
    
    var recoveryInterval: RunInterval!
    
    
    init(intensity: RunInterval, recovery: RunInterval) {
        
    }
}


enum RunIntervalType {
    case warmUp
    case recovery
    case highIntensity
}
