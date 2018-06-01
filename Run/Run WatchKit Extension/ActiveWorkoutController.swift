//
//  ActiveWorkoutController.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/31/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import WatchKit

class ActiveWorkoutController: WKInterfaceController {
    
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateUnitLabel: WKInterfaceLabel!
    
    @IBOutlet weak var totalTimeLabel:  WKInterfaceLabel!
    @IBOutlet weak var increasingTimer: WKInterfaceTimer!
    @IBOutlet weak var decreasingTimer: WKInterfaceTimer!
    @IBOutlet weak var timerGroupButton: WKInterfaceButton!
    
    @IBOutlet weak var workoutButton: WKInterfaceButton!
    
    var timer: Timer?
    
    var timeIncreasing = true
    
//    weak var workoutConfiguration: WorkoutConfiguration?
    
    var workoutManager: WorkoutManager?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let config = context as? WorkoutConfiguration {
            workoutManager = WorkoutManager(config)
            let workoutTime = config.workoutTime
            totalTimeLabel.setText(String(workoutTime.hours) + ":" + String(format: "%02d", workoutTime.minutes) + ":00")
        }
        
        updateHeartRate(0)
        updateWorkoutButton(.start)
        
        workoutManager?.heartRateUpdated = updateHeartRate
    }
    
    override func didAppear() {
        super.didAppear()
    }
    
    func startWorkout() {
        workoutManager?.checkHealthStoreAvailability { available, error in
            if available {
                do {
                    try self.workoutManager!.startWorkout()
                    DispatchQueue.main.async {
                        self.startTimers()
                    }
                } catch {
                    print("[ActiveWorkoutController] Error: Unable to start workout: \(error)")
                }
            } else if let error = error {
                print("[ActiveWorkoutController] Error: health information unavailable: \(error)")
            }
        }
    }
    
    @IBAction func timerGroupButtonAction() {
        timeIncreasing = !timeIncreasing
        increasingTimer.setHidden(!timeIncreasing)
        decreasingTimer.setHidden(timeIncreasing)
    }

    var workoutInProgress: Bool?
    
    @IBAction func workoutButtonAction() {
        if let inProgress = workoutInProgress {
            workoutInProgress = !inProgress
            updateWorkoutButton(inProgress ? .pause : .resume)
        } else {
            workoutInProgress = true
            updateWorkoutButton(.pause)
            
            if let _ = workoutManager {
                startWorkout()
            }
        }
    }

    func startTimers() {
        
        let now = Date()
        let end = Date(timeInterval: workoutManager!.workoutDurationSeconds + 1, since: now)
        
        timer = Timer.scheduledTimer(withTimeInterval: end.timeIntervalSince(now), repeats: false) { timer in
            print("done!")
        }
        
        increasingTimer.setDate(now)
        decreasingTimer.setDate(end)
        
        totalTimeLabel.setHidden(true)
        
        timerGroupButtonAction()
        
        increasingTimer.start()
        decreasingTimer.start()
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
}

enum WorkoutButtonState {
    case start
    case pause
    case resume
    
    var title:String {
        switch self {
        case .start:  return "Start Workout"
        case .pause:  return "Pause Workout"
        case .resume: return "Resume Workout"
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .start, .resume:  return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        case .pause:  return #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .start, .resume:  return #colorLiteral(red: 0.01568627451, green: 0.8705882353, blue: 0.4431372549, alpha: 1)
        case .pause:  return #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 0.17)
        }
    }
    
    var attributedTitle: NSAttributedString {
        return NSAttributedString(string: self.title, attributes: [.foregroundColor : self.textColor])
    }
}
