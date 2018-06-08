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
    case timed
    case intervals
    case stretch
    
    var title: String {
        switch self {
        case .timed: return "Timed"
        case .intervals: return "Intervals"
        case .stretch: return "Stretch"
        }
    }
    
    var image: String {
        switch self {
        case .timed: return "bar_teal"
        case .intervals: return "bar_blue"
        case .stretch: return "bar_purple"
        }
    }
    
    var controller: String {
        switch self {
        case .timed: return "NewTimedController"
        case .intervals: return "NewIntervalsController"
        case .stretch: return "NewStretchController"
        }
    }
}

class NavigationController: WKInterfaceController {

    let navItems: [NavigationItem] = [.timed, .intervals, .stretch]
    
    var selectedNavItem: NavigationItem?

    @IBOutlet weak var table: WKInterfaceTable!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        checkHealthKit()
    }
    
    
    override func willActivate() {
        super.willActivate()
        
        if let selected = selectedNavItem {
            
            switch selected {
            case .timed:
                if RunManager.shared.run is TimedRun {
                    pushController(withName: "ActiveWorkoutController", context: nil)
                }
            case .intervals, .stretch: print("[NavigationController] Stretch & Intervals Not Implemented")
            }
            
            selectedNavItem = nil
        }
    }
    
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        let navItem = navItems[rowIndex]
        
        selectedNavItem = navItem
        
        presentController(withName: navItem.controller, context: nil)
        
//        switch navItem {
//        case .timed: presentController(withName: navItem.controller, context: nil)
//        case .intervals: presentController(withName: navItem.controller, context: nil)
//        case .stretch: print("[NavigationController] Stretch Not Implemented")
//        }
    }
    
    
    func loadTable() {
        
        table.setNumberOfRows(navItems.count, withRowType: "NavigationRow")

        for i in 0..<navItems.count {
            
            let row = table.rowController(at: i) as? NavigationRowController
            
            row?.setContent(navItems[i])
        }
    }
    
    
    func checkHealthKit() {
        RunManager.shared.checkHealthStoreAvailabilityAndAuthorization { available, error in
            if available {
                DispatchQueue.main.async {
                    self.loadTable()
                }
            } else if let error = error {
                print("[ActiveWorkoutController] Error: health information unavailable: \(error)")
            }
        }
    }
}


class NavigationRowController: NSObject {
    
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var barImage: WKInterfaceImage!
    
    func setContent(_ item: NavigationItem) {
        titleLabel.setText(item.title)
        barImage.setImageNamed(item.image)
    }
}
