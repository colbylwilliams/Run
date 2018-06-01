//
//  NewWorkoutController.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/31/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import WatchKit

class NewWorkoutController: WKInterfaceController {
    
    var workoutHours: Int = 0
    var workoutMinutes: Int = 0
    
    @IBOutlet weak var saveButton: WKInterfaceButton!
    
    @IBOutlet weak var hourPicker: WKInterfacePicker!
    @IBOutlet weak var minutePicker: WKInterfacePicker!
    
    weak var workoutConfiguration: WorkoutConfiguration?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        workoutConfiguration = context as? WorkoutConfiguration
        
        hourPicker.setItems((0...3).map { $0.pickerItem("hours") })
        minutePicker.setItems((0...59).map { $0.pickerItem("minutes") })
        
        //hourPicker.setSelectedItemIndex(1)
        minutePicker.setSelectedItemIndex(1)
        
        minutePicker.focus()
        
        if let config = workoutConfiguration {
            let t = config.workoutTime
            hourPicker.setSelectedItemIndex(t.hours)
            minutePicker.setSelectedItemIndex(t.minutes)
        }
        
        updateSaveButton()
    }

    
    @IBAction func hourPickerAction(index: Int) {
        workoutHours = index
        updateSaveButton()
    }

    @IBAction func minutePickerAction(index: Int) {
        workoutMinutes = index
        updateSaveButton()
    }

    override func pickerDidSettle(_ picker: WKInterfacePicker) {
        super.pickerDidSettle(picker)
        updateSaveButton()
    }
    
    func updateSaveButton() {
        saveButton.setEnabled(workoutMinutes > 0 || workoutHours > 0)
    }
    
    @IBAction func saveButtonAction() {
        if let config = workoutConfiguration {
            config.setWorkoutDuration(hours: workoutHours, minutes: workoutMinutes)
        }
        dismiss()
    }
}


fileprivate extension Int {
    func pickerItem(_ caption: String) -> WKPickerItem {
        let item = WKPickerItem()
        item.title = String(format: "%02d", self)
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
