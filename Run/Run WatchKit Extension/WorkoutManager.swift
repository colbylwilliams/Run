//
//  WorkoutManager.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/30/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutManager: NSObject, HKWorkoutSessionDelegate {
    
    let configuration: WorkoutConfiguration
    
    let healthStore = HKHealthStore()
    
    let workoutConfiguration: HKWorkoutConfiguration = {
       
        let config = HKWorkoutConfiguration()
        
        config.activityType = .running
        config.locationType = .indoor
        
        return config
    }()
    
    var workoutSession : HKWorkoutSession?
    
    var heartRateQuery: HKAnchoredObjectQuery?
    
    var heartRateQueryAnchor: HKQueryAnchor?

    let heartRateUnit = HKUnit(from: "count/min")
    
    let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    var workoutDurationMinutes: Int { return configuration.workoutDurationMinutes }
    var workoutDurationSeconds: Double { return configuration.workoutDurationSeconds }

    var heartRateUpdated: ((_ bpm:Int) -> Void)?

    var workoutPaused: Bool {
        return workoutSession?.state != nil && workoutSession!.state == .paused
    }

    var workoutInProgress: Bool {
        return workoutSession?.state != nil && (workoutSession!.state == .running || workoutSession!.state == .paused)
    }
    
    init(_ configuration: WorkoutConfiguration) {
        self.configuration = configuration
    }
    
    
    // MARK: - HealthStore Availability & Authorization
    
    func checkHealthStoreAvailability(handler: @escaping (Bool, Error?) -> ()) {

        guard HKHealthStore.isHealthDataAvailable() else {
            handler(false, nil)
            return
        }
        
        let dataTypes = Set(arrayLiteral: heartRateQuantityType)
        
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { success, error in
            handler(success, error)
        }
    }
    
    
    // MARK: - Manage Workout
    
    func startWorkout() throws {
    
        // workout already started
        if workoutSession != nil {
            return
        }
        
        workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
        
        workoutSession?.delegate = self

        if let session = workoutSession {
            healthStore.start(session)
        }
    }
    
    func endWorkout() {
        if let session = workoutSession {
            healthStore.end(session)
        }
    }
    
    
    // MARK: - Monitor Heart Rate
    
    func startMonitoringHeartRate(_ date : Date) {
        
        guard heartRateQuery == nil else { return }

        heartRateQuery = HKAnchoredObjectQuery(type: heartRateQuantityType, predicate: nil, anchor: heartRateQueryAnchor, limit: HKObjectQueryNoLimit, resultsHandler: updateHeartRate)
        heartRateQuery!.updateHandler = updateHeartRate
        
        healthStore.execute(heartRateQuery!)
    }

    func stopMonitoringHeartRate(_ date : Date) {
        
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        
        workoutSession = nil
    }
    
    func updateHeartRate (_ query: HKAnchoredObjectQuery, _ samples: [HKSample]?, _ deleted: [HKDeletedObject]?, _ anchor: HKQueryAnchor?, _ error: Error?) {
        
        heartRateQueryAnchor = anchor
        
        guard let sample = (samples as? [HKQuantitySample])?.first else { return }
        
        let value = sample.quantity.doubleValue(for: self.heartRateUnit)
        
        heartRateUpdated?(Int(value))
        
        print("[WorkoutManager] Heart Rate: \(value) (\(sample.sourceRevision.source.name)")
    }
    

    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:  startMonitoringHeartRate(date)
        case .ended:    stopMonitoringHeartRate(date)
        default:        print("[WorkoutManager] Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        print("[WorkoutManager] Workout error")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        print("[WorkoutManager] workoutSessionDidGenerateEvent \(event)")
    }
}
