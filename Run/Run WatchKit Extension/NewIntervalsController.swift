//
//  NewIntervalsController.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 6/3/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import WatchKit

class NewIntervalsController: WKInterfaceController {
    
    fileprivate var intensityMinutes: Double = 0
    fileprivate var intensityPace: Double = 0
    fileprivate var intensityIncline: Double = 0
    fileprivate var recoveryMinutes: Double = 0
    fileprivate var recoveryPace: Double = 0
    fileprivate var recoveryIncline: Double = 0

    @IBOutlet weak var saveButton: WKInterfaceButton!

    @IBOutlet weak var intensityMinutesPicker: WKInterfacePicker!
    @IBOutlet weak var intensityPacePicker: WKInterfacePicker!
    @IBOutlet weak var intensityInclinePicker: WKInterfacePicker!

    @IBOutlet weak var recoveryMinutesPicker: WKInterfacePicker!
    @IBOutlet weak var recoveryPacePicker: WKInterfacePicker!
    @IBOutlet weak var recoveryInclinePicker: WKInterfacePicker!

    fileprivate let minutesStride = stride(from: 0.5, through: 10.0, by: 0.5)
    fileprivate let paceStride = stride(from: 1.0, through: 12.0, by: 0.1)
    fileprivate let inclineStride = stride(from: -3.0, through: 15.0, by: 0.5)

    
    //var intensityWorkout: WorkoutInterval!
    //var recoveryWorkout: WorkoutInterval!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        intensityMinutesPicker.setItems(minutesStride.map { $0.pickerItem("minutes") })
        intensityPacePicker.setItems(paceStride.map { $0.pickerItem("mph") })
        intensityInclinePicker.setItems(inclineStride.map { $0.pickerItemPercent("incline") })

        recoveryMinutesPicker.setItems(minutesStride.map { $0.pickerItem("minutes") })
        recoveryPacePicker.setItems(paceStride.map { $0.pickerItem("mph") })
        recoveryInclinePicker.setItems(inclineStride.map { $0.pickerItemPercent("incline") })

        intensityMinutesPicker.setSelectedItemIndex(1)  // 1.0
        intensityPacePicker.setSelectedItemIndex(40)    // 5.0
        intensityInclinePicker.setSelectedItemIndex(6)  // 0.0%

        recoveryMinutesPicker.setSelectedItemIndex(1)   // 1.0
        recoveryPacePicker.setSelectedItemIndex(20)     // 3.0
        recoveryInclinePicker.setSelectedItemIndex(18)  // 6.0%

        
//        if let workout = WorkoutManager.shared.workout as? IntervalWorkout {
//            intensityWorkout = workout.intensityInterval
//            recoveryWorkout = workout.recoveryInterval
//        } else {
//            intensityWorkout = WorkoutInterval(pace: 0, incline: 0)
//            recoveryWorkout = WorkoutInterval(pace: 0, incline: 0)
//        }
    }
    
    
    @IBAction func intensityMinutesPickerAction(index: Int) {
        intensityMinutes = minutesStride.item(at: index) ?? 0
        updateSaveButton()
    }

    @IBAction func intensityPacePickerAction(index: Int) {
        intensityPace = paceStride.item(at: index) ?? 0
        updateSaveButton()
    }

    @IBAction func intensityInclinePickerAction(index: Int) {
        intensityIncline = inclineStride.item(at: index) ?? 0
        updateSaveButton()
    }

    @IBAction func recoveryMinutesPickerAction(index: Int) {
        recoveryMinutes = minutesStride.item(at: index) ?? 0
        updateSaveButton()
    }

    @IBAction func recoveryPacePickerAction(index: Int) {
        recoveryPace = paceStride.item(at: index) ?? 0
        updateSaveButton()
    }

    @IBAction func recoveryInclinePickerAction(index: Int) {
        recoveryIncline = inclineStride.item(at: index) ?? 0
        updateSaveButton()
    }

    func updateSaveButton() {
        saveButton.setEnabled(validate())
    }


    @IBAction func saveButtonAction() {

        guard validate() else {
            fatalError()
        }
        
        WorkoutManager.shared.workout = IntervalWorkout(
            intensity: WorkoutInterval(pace: intensityPace, incline: intensityIncline, minutes: intensityMinutes),
            recovery:  WorkoutInterval(pace: recoveryPace, incline: recoveryIncline, minutes: recoveryMinutes)
        )
        
        dismiss()
    }


    func validate() -> Bool {
        
        guard intensityMinutes > 0 && recoveryMinutes > 0 else { return false }

        guard intensityIncline >= -3.0 && intensityIncline <= 15.0 else { return false }
        
        guard recoveryIncline >= -3.0 && recoveryIncline <= 15.0 else { return false }
        
        guard recoveryPace >= 1.0 && recoveryPace <= 12.0 else { return false }

        guard intensityPace >= 1.0 && intensityPace <= 12.0 else { return false }
        
        return true
    }
}


fileprivate extension Int {
    func pickerItem(_ caption: String) -> WKPickerItem {
        let item = WKPickerItem()
        item.title = String(format: "%02d", self)
        item.caption = caption
        return item
    }
    
    func pickerItemPercent(_ caption: String) -> WKPickerItem {
        let item = WKPickerItem()
        item.title = "\(self)%" //String(format: "%02d", self)
        item.caption = caption
        return item
    }
}

fileprivate extension Double {
    func pickerItem(_ caption: String) -> WKPickerItem {
        let item = WKPickerItem()
        item.title = String(self)
        item.caption = caption
        return item
    }
    
    func pickerItemPercent(_ caption: String) -> WKPickerItem {
        let item = WKPickerItem()
        item.title = "\(self)%" //String(format: "%02d", self)
        item.caption = caption
        return item
    }
}

