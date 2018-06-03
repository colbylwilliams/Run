//
//  NavigationController.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 5/31/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation
import WatchKit

enum NavigationItem {
    case workout
    case stretch
    
    var title: String {
        switch self {
        case .workout: return "Timed Workout"
        case .stretch: return "Stretch"
        }
    }
}

class NavigationController: WKInterfaceController {

    let navItems: [NavigationItem] = [.workout, .stretch]
    
    var selectedNavItem: NavigationItem?

    @IBOutlet weak var table: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        loadTable()
    }
    
    override func willActivate() {
        super.willActivate()
        
        if let selected = selectedNavItem {
            
            switch selected {
            case .workout:
                if WorkoutManager.shared.workoutDurationMinutes > 0 {
                    pushController(withName: "ActiveWorkoutController", context: nil)
                }
            case .stretch: print("[NavigationController] Stretch Not Implemented")
            }
            
            selectedNavItem = nil
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        let navItem = navItems[rowIndex]
        
        selectedNavItem = navItem
        
        switch navItem {
        case .workout:
            presentController(withName: "NewWorkoutController", context: nil)
        case .stretch: print("[NavigationController] Stretch Not Implemented")
        }
    }
    
    func loadTable() {
        
        table.setNumberOfRows(navItems.count, withRowType: "NavigationRow")

        for i in 0..<navItems.count {
            
            let row = table.rowController(at: i) as? NavigationRowController
            
            row?.setContent(navItems[i])
        }
    }
}

class NavigationRowController: NSObject {
    
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    
    func setContent(_ item: NavigationItem) {
        titleLabel.setText(item.title)
    }
}
