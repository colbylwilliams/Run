//
//  NewTimedController.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 6/3/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import WatchKit

class NewTimedController: WKInterfaceController {
    
    fileprivate var hours: Int = 0
    fileprivate var minutes: Int = 0
    fileprivate var seconds: Int = 0
    
    fileprivate var pace: Double = 0
    fileprivate var incline: Double = 0
    
    @IBOutlet weak var saveButton: WKInterfaceButton!
    
    @IBOutlet weak var hourPicker: WKInterfacePicker!
    @IBOutlet weak var minutePicker: WKInterfacePicker!
    @IBOutlet weak var secondsPicker: WKInterfacePicker!
    
    @IBOutlet weak var pacePicker: WKInterfacePicker!
    @IBOutlet weak var inclinePicker: WKInterfacePicker!
    
    fileprivate let secondsStride = stride(from: 0, through: 45, by: 15)
    fileprivate let paceStride = stride(from: 1.0, through: 12.0, by: 0.1)
    fileprivate let inclineStride = stride(from: -3.0, through: 15.0, by: 0.5)
    
    var workout: TimedWorkout!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        hourPicker.setItems((0...3).map { $0.pickerItem("hours") })
        minutePicker.setItems((0...59).map { $0.pickerItem("minutes") })
        secondsPicker.setItems(secondsStride.map { $0.pickerItem("seconds") })
        
        pacePicker.setItems(paceStride.map { $0.pickerItem("mph") })
        inclinePicker.setItems(inclineStride.map { $0.pickerItemPercent("incline") })
        
        workout = WorkoutManager.shared.workout as? TimedWorkout ?? TimedWorkout(pace: 0, incline: 0)
        
        if workout.duration > 0 {
            let t = workout.durationComponents()
            hourPicker.setSelectedItemIndex(t.hours)
            minutePicker.setSelectedItemIndex(t.minutes)
            secondsPicker.setSelectedItemIndex(t.seconds < 15 ? 0 : t.seconds < 30 ? 1 : t.seconds < 45 ? 2 : 3)
        } else {
            //hourPicker.setSelectedItemIndex(1)
            minutePicker.setSelectedItemIndex(1)
        }
        
        pacePicker.setSelectedItemIndex(20)
        inclinePicker.setSelectedItemIndex(6)

        minutePicker.setEnabled(true)
        minutePicker.focus()
        
        updateSaveButton()
    }
    
    
    @IBAction func hourPickerAction(index: Int) {
        hours = index
        updateSaveButton()
    }
    
    @IBAction func minutePickerAction(index: Int) {
        minutes = index
        updateSaveButton()
    }

    @IBAction func secondsPickerAction(index: Int) {
        seconds = secondsStride.item(at: index) ?? 0
        updateSaveButton()
    }

    @IBAction func pacePickerAction(index: Int) {
        pace = paceStride.item(at: index) ?? 0
        updateSaveButton()
    }

    @IBAction func inclinePickerAction(index: Int) {
        incline = inclineStride.item(at: index) ?? 0
        updateSaveButton()
    }

    
    override func pickerDidSettle(_ picker: WKInterfacePicker) {
        super.pickerDidSettle(picker)
        updateSaveButton()
    }
    
    func updateSaveButton() {
        saveButton.setEnabled(validate())
    }
    

    @IBAction func saveButtonAction() {

        guard validate() else {
            fatalError()
        }
        
        workout.pace = pace
        workout.incline = incline
        workout.setDuration(hours: hours, minutes: minutes, seconds: seconds)
        
        WorkoutManager.shared.workout = workout
        
        dismiss()
    }
    
    func validate() -> Bool {
        
        guard minutes > 0 || hours > 0 || seconds > 0 else { return false }

        guard incline >= -3.0 && incline <= 15.0 else { return false }
        
        guard pace >= 1.0 && pace <= 12.0 else { return false }
        
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
        item.title = String(self) //String(format: "%02d", self)
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


//var monospaced: UIFont {
//    let settings = [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType, UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]]
//
//    let attributes = [UIFontDescriptor.AttributeName.featureSettings: settings]
//    let newDescriptor = fontDescriptor.addingAttributes(attributes)
//    return UIFont(descriptor: newDescriptor, size: 0)
//}
