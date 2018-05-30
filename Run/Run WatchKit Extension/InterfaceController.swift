//
//  InterfaceController.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/30/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    let workoutManager = WorkoutManager()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
    }
    
    override func didAppear() {
        super.didAppear()
        
        workoutManager.checkHealthStoreAvailability { available, error in
            if available {
                do {
                    try self.workoutManager.startWorkout()
                } catch {
                    print("Error: Unable to start workout: \(error)")
                }
            } else if let error = error {
                print("Error: health information unavailable: \(error)")
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
