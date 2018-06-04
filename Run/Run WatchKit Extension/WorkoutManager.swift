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
    
    static let shared: WorkoutManager = WorkoutManager()
    
    fileprivate override init() { }
    
    
    // MARK: - HealthKit
    
    fileprivate let healthStore = HKHealthStore()
    
    fileprivate var workoutSession : HKWorkoutSession?
    
    fileprivate let workoutConfiguration: HKWorkoutConfiguration = {
       
        let config = HKWorkoutConfiguration()
        
        config.activityType = .running
        config.locationType = .indoor
        
        return config
    }()
    
    fileprivate var heartRateQueryAnchor: HKQueryAnchor?
    
    fileprivate var heartRateQuery: HKAnchoredObjectQuery?


    
    fileprivate var workoutTimer: Timer?


    var workout: Workout?
    
    var workoutState: HKWorkoutSessionState { return workoutSession?.state ?? .notStarted }
    


    // MARK: - Actions & Events
    
    var heartRateUpdated: ((_ bpm:Int) -> Void)?
    
    var timerDatesUpdated: ((_ increasing:Date?, _ decreasing:Date?) -> Void)?
    
    var workoutStateChanged: ((_ to: HKWorkoutSessionState, _ from: HKWorkoutSessionState, _ date: Date) -> Void)?

    
    
    // MARK: - HealthStore Availability & Authorization
    
    func checkHealthStoreAvailabilityAndAuthorization(completion: @escaping (Bool, Error?) -> Void) {

        guard HKHealthStore.isHealthDataAvailable() else {
            print("[WorkoutManager] Error: Health Data Unavailable")
            completion(false, nil)
            return
        }
        
        let dataTypes = Set(arrayLiteral: WorkoutUnits.heartRateQuantityType)
        
        return healthStore.requestAuthorization(toShare: nil, read: dataTypes, completion: completion)
    }
    
    
    // MARK: - Manage Workout
    
    func startWorkout() throws {
    
        guard workout != nil else { throw WorkoutManagerError.workoutNil }
        guard workout!.duration > 0 else { throw WorkoutManagerError.workoutDuration }
        
        
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
        if let session = workoutSession, (session.state == .running || session.state == .paused) {
            healthStore.end(session)
        }
    }
    
    
    // MARK: - Monitor Heart Rate
    
    fileprivate func startMonitoringHeartRate(_ date : Date) {
        
        guard heartRateQuery == nil else { return }

        // TODO: consider constraining the query to session start date
        
        heartRateQuery = HKAnchoredObjectQuery(type: WorkoutUnits.heartRateQuantityType, predicate: nil, anchor: heartRateQueryAnchor, limit: HKObjectQueryNoLimit, resultsHandler: updateHeartRate)
        heartRateQuery!.updateHandler = updateHeartRate
        
        healthStore.execute(heartRateQuery!)
    }

    fileprivate func stopMonitoringHeartRate(_ date : Date) {
        
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        
        heartRateUpdated?(0)
    }
    
    fileprivate func updateHeartRate (_ query: HKAnchoredObjectQuery, _ samples: [HKSample]?, _ deleted: [HKDeletedObject]?, _ anchor: HKQueryAnchor?, _ error: Error?) {
        
        heartRateQueryAnchor = anchor
        
        guard let sample = (samples as? [HKQuantitySample])?.first else {
            print("[WorkoutManager] Heart Rate: No Data or Unauthorized")
            return
        }
        
        let value = sample.quantity.doubleValue(for: WorkoutUnits.heartRateUnit)
        
        heartRateUpdated?(Int(value))
        
        //print("[WorkoutManager] Heart Rate: \(value) (\(sample.sourceRevision.source.name))")
    }

    fileprivate func updateTimer() {
        
        //print("[WorkoutManager] Workout Running Seconds: \(workoutRunningSeconds)  \(workout.durationCompleted())")
        
        invalidateWorkoutTimer()
        
        guard let durations = workout?.durations() else { return }
        
        DispatchQueue.main.async {
            self.workoutTimer = Timer.scheduledTimer(withTimeInterval: durations.remaining, repeats: false) { timer in
                print("done!")
                self.endWorkout()
            }
        }
        
        let startDate = Date(timeIntervalSinceNow: -(durations.completed + 1))
        let endDate = Date(timeInterval: durations.total + 1, since: startDate)
        
        timerDatesUpdated?(startDate, endDate)
    }
    
    fileprivate func invalidateWorkoutTimer() {
        if workoutTimer?.isValid ?? false {
            workoutTimer!.invalidate()
            workoutTimer = nil
        }
    }
    
    
    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        print("[WorkoutManager] Workout Session changed state: from \(fromState.name) to \(toState.name) at \(date)")
        
        //print("[WorkoutManager] Start: \(workoutSession.startDate?.description ?? "nil")")
        //print("[WorkoutManager] Date:  \(date.description)")
        //print("[WorkoutManager] End:   \(workoutSession.endDate?.description ?? "nil")")
        
        
        switch toState {
        case .running:
                        
            updateTimer()
            startMonitoringHeartRate(date)
        
        case .ended:
            
            if let start = workoutSession.startDate {
                workout?.addRunningDates(start: start, end: date)
            }
            
            timerDatesUpdated?(nil, nil)
            stopMonitoringHeartRate(date)
        
            //guard let durations = workout?.durations() else {
                //print("nope")
                //return
            //}
            
            //print("[WorkoutManager] Workout StartDate: \(workout!.startDate!)")
            //print("[WorkoutManager] Workout EndDate:   \(workout!.endDate!)")
            //print("[WorkoutManager] Workout Duration:  \(durations.total)")
            //print("[WorkoutManager] Workout Completed: \(durations.completed)")
            //print("[WorkoutManager] Workout Remaining: \(durations.remaining)")
            
        case .paused:
            
            if let start = workoutSession.startDate {
                workout?.addRunningDates(start: start, end: date)
                //print("[WorkoutManager] Workout Running Seconds: \(workout.durationCompleted())")
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
        //let metadata = event.metadata?.compactMap { "\($0.key) : \($0.value)" }.joined(separator: ", ") ?? ""
        //print("[WorkoutManager] Session Event: Type: \(event.type.name)  DateInterval: \(event.dateInterval)  Metadata: [ \(metadata) ]")
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
