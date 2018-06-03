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
    
    
    // MARK: - Workout Duration
    
    fileprivate(set) var workoutDurationMinutes: Int = 0
    
    fileprivate(set) var workoutRunningSeconds: Double = 0
    
    
    var workoutDurationSeconds: Double { return Double (workoutDurationMinutes * 60) }
    
    func setWorkoutDuration(hours: Int, minutes: Int) { workoutDurationMinutes = (hours * 60) + minutes }
    
    var workoutTime: (hours:Int, minutes:Int) { return (workoutDurationMinutes / 60, workoutDurationMinutes % 60) }
    
    var workoutTimer: Timer?
    
    
    // MARK: - Heart Rate
    
    var targetHeartRate: Double?

    
    // MARK: - HealthKit
    
    let healthStore = HKHealthStore()
    
    var workoutSession : HKWorkoutSession?
    
    let workoutConfiguration: HKWorkoutConfiguration = {
       
        let config = HKWorkoutConfiguration()
        
        config.activityType = .running
        config.locationType = .indoor
        
        return config
    }()
    
    
    var heartRateQueryAnchor: HKQueryAnchor?
    
    var heartRateQuery: HKAnchoredObjectQuery?

    let heartRateUnit = HKUnit(from: "count/min")
    
    let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    

    var heartRateUpdated: ((_ bpm:Int) -> Void)?
    
    var workoutStateChanged: ((_ to: HKWorkoutSessionState, _ from: HKWorkoutSessionState, _ date: Date) -> Void)?
    

    var workoutState: HKWorkoutSessionState { return workoutSession?.state ?? .notStarted }
    
    var workoutPaused: Bool { return workoutState == .paused }

    var workoutInProgress: Bool { return workoutState == .running || workoutState == .paused }
    
    static let shared: WorkoutManager = WorkoutManager()
    
    
    var timerEndDate: Date?
    var timerStartDate: Date?
    
    var timerDatesUpdated: ((_ increasing:Date?, _ decreasing:Date?) -> Void)?

    
    fileprivate override init() { }
    
    
    // MARK: - HealthStore Availability & Authorization
    
    func checkHealthStoreAvailabilityAndAuthorization(completion: @escaping (Bool, Error?) -> Void) {

        guard HKHealthStore.isHealthDataAvailable() else {
            print("[WorkoutManager] Error: Health Data Unavailable")
            completion(false, nil)
            return
        }
        
        let dataTypes = Set(arrayLiteral: heartRateQuantityType)
        
        return healthStore.requestAuthorization(toShare: nil, read: dataTypes, completion: completion)
    }
    
    
    // MARK: - Manage Workout
    
    func startWorkout() throws {
    
        // workout already started
        guard workoutSession == nil else { return }
        
        workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
        
        workoutSession?.delegate = self

        if let session = workoutSession {
            healthStore.start(session)
        }
    }

    func pauseWorkout() {
        if let session = workoutSession, session.state == .running {
            healthStore.pause(session)
        }
    }
    
    func resumeWorkout() {
        if let session = workoutSession, session.state == .paused {
            healthStore.resumeWorkoutSession(session)
        }
    }
    
    func endWorkout() {
        // TODO: may need to check for a paused workout, resume it, then end it...?
        // If the session is not running, the system returns an invalidArgumentException exception
        if let session = workoutSession, session.state == .running {
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
    }
    
    func updateHeartRate (_ query: HKAnchoredObjectQuery, _ samples: [HKSample]?, _ deleted: [HKDeletedObject]?, _ anchor: HKQueryAnchor?, _ error: Error?) {
        
        heartRateQueryAnchor = anchor
        
        guard let sample = (samples as? [HKQuantitySample])?.first else {
            print("[WorkoutManager] Heart Rate: No Data or Unauthorized")
            return
        }
        
        let value = sample.quantity.doubleValue(for: self.heartRateUnit)
        
        heartRateUpdated?(Int(value))
        
        //print("[WorkoutManager] Heart Rate: \(value) (\(sample.sourceRevision.source.name))")
    }

    func updateTimer() {
        
        print("[WorkoutManager] Workout Running Seconds: \(workoutRunningSeconds)")
        
        invalidateWorkoutTimer()
        
        timerStartDate = Date(timeIntervalSinceNow: -(workoutRunningSeconds + 1))
        timerEndDate = Date(timeInterval: workoutDurationSeconds + 1, since: timerStartDate!)
        
        DispatchQueue.main.async {
            self.workoutTimer = Timer.scheduledTimer(withTimeInterval: self.workoutDurationSeconds - self.workoutRunningSeconds, repeats: false) { timer in
                print("done!")
                self.endWorkout()
            }
        }
        
        timerDatesUpdated?(timerStartDate, timerEndDate)
    }
    
    func invalidateWorkoutTimer() {
        if workoutTimer?.isValid ?? false {
            workoutTimer!.invalidate()
            workoutTimer = nil
        }
    }
    
    
    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        print("[WorkoutManager] Workout Session changed state to \(toState.name) from \(fromState.name) at \(date)")
        
        switch toState {
        case .running:
            updateTimer()
            startMonitoringHeartRate(date)
        
        case .ended:
            timerDatesUpdated?(nil, nil)
            stopMonitoringHeartRate(date)
        
        case .paused:
            if let start = workoutSession.startDate {
                workoutRunningSeconds += date.timeIntervalSince(start)
                print("[WorkoutManager] Workout Running Seconds: \(workoutRunningSeconds)")
            }
            
            invalidateWorkoutTimer()
            timerDatesUpdated?(nil, nil)

        default: print("[WorkoutManager] Unexpected state \(toState.name)")
        }
        
        workoutStateChanged?(toState, fromState, date)
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        print("[WorkoutManager] Workout error")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        let metadata = event.metadata?.compactMap { "\($0.key) : \($0.value)" }.joined(separator: ", ") ?? ""
        print("[WorkoutManager] Session Event: Type: \(event.type.name)  DateInterval: \(event.dateInterval)  Metadata: [ \(metadata) ]")
    }
}


fileprivate extension HKWorkoutSessionState {
    var name: String {
        switch self {
        case .notStarted: return "NotStarted"
        case .running: return "Running"
        case .ended: return "Ended"
        case .paused: return "Paused"
        }
    }
}

fileprivate extension HKWorkoutEventType {
    var name: String {
        switch self {
        case .pause:        return "Pause"
        case .resume: return "Resume"
        case .motionPaused: return "MotionPaused"
        case .motionResumed: return "MotionResumed"
        case .pauseOrResumeRequest: return "PauseOrResumeRequest"
        case .lap: return "Lap"
        case .segment: return "Segment"
        case .marker: return "Marker"
        }
    }
}
