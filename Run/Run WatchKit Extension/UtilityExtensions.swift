//
//  UtilityExtensions.swift
//  Run WatchKit Extension
//
//  Created by Colby L Williams on 6/3/18.
//  Copyright © 2018 Colby L Williams. All rights reserved.
//

import Foundation

extension StrideThrough {
    func item(at index: Int) -> Element? {
        return self.enumerated().first { $0.offset == index }?.element
    }
}
