//
//  ViewController.swift
//  Run
//
//  Created by Colby L Williams on 5/30/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func requestAction(_ sender: Any) {
        
        let heartRateQuantityType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[WorkoutManager] Error: Health Data Unavailable")
            return
        }
        
        let dataTypes = Set(arrayLiteral: heartRateQuantityType)
        
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { success, error in

            print("Success: \(success) : Error: \(error?.localizedDescription ?? "nil")")
        }
    }
}

