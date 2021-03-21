//
//  MeterToInches.swift
//  HangHelper
//
//  Created by Cao Mai on 3/18/21.
//

import Foundation

struct MeterToInches {
    let meter: Float
    
    func toFeetAndInches() -> String {
        var inches: Float = 0.0
        inches = meter * 39.3701
        
        if inches > 12.0 {
            let feet = Int(inches) / 12
            
            inches = inches - Float(feet * 12)
            
            return String(feet) + "'" + numToString(number: inches) + "in"
        }
        
        return numToString(number: inches) + "in"
    }
    
    func numToString(number: Float) -> String {
        return String(format: "%.2f", number)

    }

}
