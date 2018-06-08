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
        
        RunManager.shared.heartRateUpdated = updateHeartRate
        RunManager.shared.workoutStateChanged = workoutStateChanged
        RunManager.shared.timerDatesUpdated = updateTimers
        
        setupTimers()
        
        do {
            try RunManager.shared.prepare()
        } catch {
            print("[ActiveWorkoutController] Error: Unable to prepare workout: \(error.localizedDescription)")
        }
    }
    
    
    @IBAction func timerGroupButtonAction() {
        timeIncreasing = !timeIncreasing
        increasingTimer.setHidden(!timeIncreasing)
        decreasingTimer.setHidden(timeIncreasing)
    }
    
    @IBAction func workoutButtonAction() {

        let workoutState = RunManager.shared.workoutState

        print("workoutState: \(workoutState.name)")
        
        switch workoutState {
        case .prepared,
             .notStarted: RunManager.shared.startActivity()
        case .running:    RunManager.shared.pause()
        case .paused:     RunManager.shared.resume()
        case .stopped:    RunManager.shared.end()
        case .ended:      print("[ActiveWorkoutController] Error: Save Workout Not Implemented")
        }
    }
    

    func updateTimers (_ session: HKWorkoutSession, _ increasing:Date?, _ decreasing:Date?) {
        
        DispatchQueue.main.async {
            if let i = increasing, let d = decreasing {
                self.increasingTimer.setDate(i)
                self.decreasingTimer.setDate(d)
            }
            session.state == .running ? self.increasingTimer.start() : self.increasingTimer.stop()
            session.state == .running ? self.decreasingTimer.start() : self.decreasingTimer.stop()
        }
    }

    func setupTimers() {
        
        if let run = RunManager.shared.run {
            
            let now = Date()
            let end = Date(timeInterval: run.duration + 1, since: now)
            
            increasingTimer.setDate(now)
            decreasingTimer.setDate(end)
        }
    }
    
    
    func updateWorkoutButton(_ state: WorkoutButtonState) {
        workoutButton.setBackgroundColor(state.backgroundColor)
        workoutButton.setAttributedTitle(state.attributedTitle)
    }
    
    
    func updateHeartRate(_ bpm: Int) {
        DispatchQueue.main.async {
            self.heartRateLabel.setText(bpm > 0 ? String(bpm) : "--")
            self.heartRateUnitLabel.setText(bpm > 0 ? "BPM" : nil)
        }
    }
    
    func workoutStateChanged (_ session: HKWorkoutSession, _ to: HKWorkoutSessionState, _ from: HKWorkoutSessionState, _ date: Date) {
        DispatchQueue.main.async {
            self.updateWorkoutButton(WorkoutButtonState(forState: to))
        }
    }
}

enum WorkoutButtonState {
    case start
    case pause
    case resume
    case end
    case save
    
    init(forState state: HKWorkoutSessionState) {
        switch state {
        case .prepared,
             .notStarted:   self = .start
        case .running:      self = .pause
        case .paused:       self = .resume
        case .stopped:      self = .end
        case .ended:        self = .save
        }
    }
    
    var title:String {
        switch self {
        case .start:  return "Start Workout"
        case .pause:  return "Pause Workout"
        case .resume: return "Resume Workout"
        case .end:    return "Finish Workout"
        case .save:   return "Save Workout"
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .start, .resume, .save:  return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        case .pause: return #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
        case .end:   return #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 1, alpha: 1)
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .start, .resume:  return #colorLiteral(red: 0.01568627451, green: 0.8705882353, blue: 0.4431372549, alpha: 1)
        case .pause: return #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 0.17)
        case .end:   return #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
        case .save:  return #colorLiteral(red: 0, green: 0.9607843137, blue: 0.9176470588, alpha: 1)
        }
    }
    
    var attributedTitle: NSAttributedString {
        return NSAttributedString(string: self.title, attributes: [.foregroundColor : self.textColor])
    }
}
