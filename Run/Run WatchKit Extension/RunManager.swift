//
//  RunManager.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/30/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import HealthKit

class RunManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    
    static let shared: RunManager = RunManager()
    
    fileprivate override init() { }
    
    
    // MARK: - HealthKit
    
    fileprivate let healthStore = HKHealthStore()
    
    fileprivate var workoutSession: HKWorkoutSession!
    
    fileprivate var workoutBuilder: HKLiveWorkoutBuilder { return workoutSession.associatedWorkoutBuilder() }
    
    fileprivate var workoutBuilderDataSource: HKLiveWorkoutDataSource?
    
    fileprivate let workoutConfiguration: HKWorkoutConfiguration = {
       
        let config = HKWorkoutConfiguration()
        
        config.activityType = .running
        config.locationType = .indoor
        
        return config
    }()
    
    fileprivate let shareTypes: Set = [ HKQuantityType.workoutType() ]
    
    fileprivate let readTypes: Set = [
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]


    fileprivate var workoutTimer: Timer?


    var run: Run!
    
    var workoutState: HKWorkoutSessionState { return workoutSession?.state ?? .notStarted }
    


    // MARK: - Actions & Events
    
    var heartRateUpdated: ((_ bpm: Int) -> Void)?
    
    var timerDatesUpdated: ((_ session: HKWorkoutSession, _ increasing: Date?, _ decreasing: Date?) -> Void)?
    
    var workoutStateChanged: ((_ session: HKWorkoutSession, _ to: HKWorkoutSessionState, _ from: HKWorkoutSessionState, _ date: Date) -> Void)?

    
    
    // MARK: - HealthStore Availability & Authorization
    
    func checkHealthStoreAvailabilityAndAuthorization(completion: @escaping (Bool, Error?) -> Void) {

        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, RunManagerError(kind: .healthDataUnavailable)); return
        }
        
        return healthStore.requestAuthorization(toShare: shareTypes, read: readTypes, completion: completion)
    }
    
    
    // MARK: - Manage Workout
    
    func prepare() throws {
    
        guard run != nil else { throw RunManagerError(kind: .runNil) }
        guard run!.duration > 0 else { throw RunManagerError(kind: .runDuration) }
        guard workoutSession == nil else { throw RunManagerError(kind: .sessionNotNil) }
        
        workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        
        guard workoutSession != nil else { throw RunManagerError(kind: .sessionInitFailed) }
        
        workoutSession.delegate = self
        
        workoutBuilderDataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
        
        workoutBuilder.dataSource = workoutBuilderDataSource
        workoutBuilder.delegate = self
        
        workoutSession.prepare()
    }

    func startActivity() {
        let date = Date()
        workoutSession.startActivity(with: date)
        workoutBuilder.beginCollection(withStart: date) { (success, error) in
            if let e = error { print(e.localizedDescription) }
        }
    }
    
    func pause() { workoutSession.pause() }
    
    func resume() { workoutSession.resume() }
    
    func stopActivity() { workoutSession.stopActivity(with: Date()) }
    
    func end() { workoutSession.end() }

    
    fileprivate func updateTimer() {
        
        invalidateWorkoutTimer()
        
        print("duration: \(run.duration)")
        print("elapsed:  \(workoutBuilder.elapsedTime)")
        print("interval: \(self.run.duration - self.workoutBuilder.elapsedTime)")
        
        DispatchQueue.main.async {
            self.workoutTimer = Timer.scheduledTimer(withTimeInterval: (self.run.duration - self.workoutBuilder.elapsedTime), repeats: false) { timer in
                print("Finished: \(self.workoutBuilder.elapsedTime)")
                self.stopActivity()
            }
        }
        
        let startDate = Date(timeIntervalSinceNow: -(workoutBuilder.elapsedTime + 1))
        let endDate = Date(timeInterval: run.duration + 1, since: startDate)
        
        timerDatesUpdated?(workoutSession, startDate, endDate)
    }
    
    
    fileprivate func invalidateWorkoutTimer(andNotify notify: Bool = false) {
        print("invalidate")
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        if notify { timerDatesUpdated?(workoutSession, nil, nil) }
    }
    
    
    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
        print("[RunManager] Workout Session changed state: from \(fromState.name) to \(toState.name) at \(date)")
        
        print("date: \(date.description)")
        print("StartData: \(workoutSession.startDate?.description ?? "")")
        print("elapsedTime: \(String(workoutBuilder.elapsedTime))")
        
        switch toState {
        //case .prepared:
        case .running:  updateTimer()
        case .paused,
             .stopped: invalidateWorkoutTimer(andNotify: true)
        case .ended:
            workoutBuilder.endCollection(withEnd: date) { (success, error) in
                if let e = error { print(e.localizedDescription) }
            }
        default: print("[RunManager] Unexpected state \(toState.name)")
        }
        
        workoutStateChanged?(workoutSession, toState, fromState, date)
    }
    
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("[RunManager] WorkoutSession Failed with error: \(error.localizedDescription)")
    }
    
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        let metadata = event.metadata?.compactMap { "\($0.key) : \($0.value)" }.joined(separator: ", ") ?? ""
        print("[RunManager] Session Event: Type: \(event.type.name)  DateInterval: \(event.dateInterval)  Metadata: [ \(metadata) ]")
    }
    
    
    
    // MARK: - HKLiveWorkoutBuilderDelegate
    
    // Called every time a new event is added to the workout builder.
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("[RunManager] WorkoutBuilder Did Collect Event: [ \(workoutBuilder.workoutEvents.map{ $0.type.name }.joined(separator: ", ")) ]")
    }
    
    // Called every time new samples are added to the workout builder.
    // With new samples added, statistics for the collectedTypes may have changed and should be read again
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
        //print("[RunManager] WorkoutBuilder Did Collect Data of Types: (\(workoutBuilder.elapsedTime)) [ \(collectedTypes.map{ $0.name }.joined(separator: ", ")) ]")
        
        let heartRateUnit = HKUnit(from: "count/min")
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        if collectedTypes.contains(heartRateType) {
            let stats = workoutBuilder.statistics(for: heartRateType)
            if let newHeartRate = stats?.mostRecentQuantity()?.doubleValue(for: heartRateUnit), newHeartRate > 0 {
                heartRateUpdated?(Int(newHeartRate))
            }
        }
        
        // if let type = collectedTypes.first as? HKQuantityType { print(workoutBuilder.statistics(for: type) ?? "no")
    }
}


struct RunManagerError: Error, LocalizedError {
    
    enum ErrorKind {
        case runNil
        case runDuration
        case sessionNotNil
        case sessionInitFailed
        case sessionInvalidState
        case healthDataUnavailable
    }
    
    let kind: ErrorKind
    
    var errorDescription: String? {
        switch kind {
        case .runNil: return "There is no Run object set in the shared WorkoutManager.  This state is invalid and shouldn't happen."
        case .runDuration: return "The Run object set in the shared WorkoutManager has a duration of 0.  This state is invalid and shouldn't happen."
        case .sessionNotNil: return "You are attempting to configure the WorkoutSession on the shared WorkoutManager when the WorkoutSession already exists."
        case .sessionInitFailed: return "Failed to initialize workout session."
        case .sessionInvalidState: return "The WorkoutSession on the shared WorkoutManager is in an invalid state for this operation."
        case .healthDataUnavailable: return "Health Data is Unavailable at this time."
        }
    }
}


extension HKWorkoutSessionState {
    var name: String {
        switch self {
        case .notStarted: return "NotStarted"
        case .prepared:   return "Prepared"
        case .running:    return "Running"
        case .paused:     return "Paused"
        case .stopped:    return "Stopped"
        case .ended:      return "Ended"
        }
    }
}

fileprivate extension HKWorkoutEventType {
    var name: String {
        switch self {
        case .pause:                return "Pause"
        case .resume:               return "Resume"
        case .motionPaused:         return "MotionPaused"
        case .motionResumed:        return "MotionResumed"
        case .pauseOrResumeRequest: return "PauseOrResumeRequest"
        case .lap:                  return "Lap"
        case .segment:              return "Segment"
        case .marker:               return "Marker"
        }
    }
}

fileprivate extension HKSampleType {
    var name: String {
        let id = HKQuantityTypeIdentifier(rawValue: self.identifier)
        switch id {
        case .heartRate: return "Heart Rate"
        case .activeEnergyBurned: return "Active Energy Burned"
        case .distanceWalkingRunning: return "Distance Walking or Running"
        default: return "Dont Care"
        }
    }
}
