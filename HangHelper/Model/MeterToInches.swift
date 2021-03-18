//
//  MeterToInches.swift
//  HangHelper
//
//  Created by Cao Mai on 3/18/21.
//

import Foundation

struct MeterToInches {
    let meter: Float
    
    func convertToInches() -> Float {
        var inches: Float = 0.0
        inches = meter * 39.3701
        
        return inches
    }
}
