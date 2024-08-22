//
//  File.swift
//  
//
//  Created by 홍승아 on 5/30/24.
//

import Foundation

struct VerificationCodeGenerator{
    
    func generate() -> Int{
        var result = 0
        var n = 1
        
        for _ in 1...6{
            let randomNum = Int.random(in: 1...9)
            result += randomNum * n
            n *= 10
        }
        
        return result
    }
}
