//
//  ActiveWorkoutController.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/31/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import WatchKit
import HealthKit

class ActiveWorkoutController: WKInterfaceController {
    
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateUnitLabel: WKInterfaceLabel!
    
    @IBOutlet weak var totalTimeLabel:  WKInterfaceLabel!
    @IBOutlet weak var increasingTimer: WKInterfaceTimer!
    @IBOutlet weak var decreasingTimer: WKInterfaceTimer!
    @IBOutlet weak var timerGroupButton: WKInterfaceButton!
    
    @IBOutlet weak var workoutButton: WKInterfaceButton!
    
    
    var timeIncreasing = false
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        updateHeartRate(0)
        updateWorkoutButton(.start)
        
        WorkoutManager.shared.heartRateUpdated = updateHeartRate
        WorkoutManager.shared.workoutStateChanged = workoutStateChanged
        WorkoutManager.shared.timerDatesUpdated = updateTimers
        
        setupTimers()
    }
    
    
    func startWorkout() {
        do {
            try WorkoutManager.shared.startWorkout()
        } catch {
            print("[ActiveWorkoutController] Error: Unable to start workout: \(error)")
        }
    }
    
    @IBAction func timerGroupButtonAction() {
        timeIncreasing = !timeIncreasing
        increasingTimer.setHidden(!timeIncreasing)
        decreasingTimer.setHidden(timeIncreasing)
    }
    
    @IBAction func workoutButtonAction() {

        let workoutState = WorkoutManager.shared.workoutState

        switch workoutState {
        case .notStarted: startWorkout()
        case .running:    WorkoutManager.shared.pauseWorkout()
        case .paused:     WorkoutManager.shared.resumeWorkout()
        case .ended:      print("[ActiveWorkoutController] Error: Save Workout Not Implemented")
        }
    }
    

    func updateTimers (_ increasing:Date?, _ decreasing:Date?) {
        DispatchQueue.main.async {
            if let i = increasing, let d = decreasing {
                self.increasingTimer.setDate(i)
                self.decreasingTimer.setDate(d)
                
                self.increasingTimer.start()
                self.decreasingTimer.start()
            } else {
                self.increasingTimer.stop()
                self.decreasingTimer.stop()
            }
        }
    }

    func setupTimers() {
        
        if let workout = WorkoutManager.shared.workout {
            
            let now = Date()
            let end = Date(timeInterval: workout.duration + 1, since: now)
            
            increasingTimer.setDate(now)
            decreasingTimer.setDate(end)
        }
    }
    
    
    func updateWorkoutButton(_ state:WorkoutButtonState) {
        workoutButton.setBackgroundColor(state.backgroundColor)
        workoutButton.setAttributedTitle(state.attributedTitle)
    }
    
    
    func updateHeartRate(_ bpm:Int) {
        DispatchQueue.main.async {
            self.heartRateLabel.setText(bpm > 0 ? String(bpm) : "--")
            self.heartRateUnitLabel.setText(bpm > 0 ? "BPM" : nil)
        }
    }
    
    func workoutStateChanged (_ to: HKWorkoutSessionState, _ from: HKWorkoutSessionState, _ date: Date) {
        
        DispatchQueue.main.async {
            self.updateWorkoutButton(WorkoutButtonState(forState: to))
            //self.startTimers()
        }

//        let start = WorkoutManager.shared.startDate != nil ? "\(WorkoutManager.shared.startDate!)" : ""
//
//        switch to {
//        case .notStarted:   print("[ActiveWorkoutController] State Changed: Not Started \(start) \(date)")
//        case .running:      print("[ActiveWorkoutController] State Changed: Running \(start) \(date)")
//        case .paused:       print("[ActiveWorkoutController] State Changed: Paused \(start) \(date)")
//        case .ended:        print("[ActiveWorkoutController] State Changed: Ended (Save Workout) \(start) \(date)")
//        }
    }
}

enum WorkoutButtonState {
    case start
    case pause
    case resume
    case save
    
    init(forState state: HKWorkoutSessionState) {
        switch state {
        case .notStarted:   self = .start
        case .running:      self = .pause
        case .paused:       self = .resume
        case .ended:        self = .save
        }
    }
    
    var title:String {
        switch self {
        case .start:  return "Start Workout"
        case .pause:  return "Pause Workout"
        case .resume: return "Resume Workout"
        case .save:   return "Save Workout"
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .start, .resume, .save:  return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        case .pause: return #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .start, .resume:  return #colorLiteral(red: 0.01568627451, green: 0.8705882353, blue: 0.4431372549, alpha: 1)
        case .pause: return #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 0.17)
        case .save:  return #colorLiteral(red: 0, green: 0.9607843137, blue: 0.9176470588, alpha: 1)
        }
    }
    
    var attributedTitle: NSAttributedString {
        return NSAttributedString(string: self.title, attributes: [.foregroundColor : self.textColor])
    }
}
