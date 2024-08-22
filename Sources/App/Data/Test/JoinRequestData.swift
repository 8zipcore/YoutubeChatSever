//
//  File.swift
//  
//
//  Created by 홍승아 on 6/7/24.
//

import Vapor

struct EmailVerificationRequestData: Content{
    var id: UUID
    var verificationCode: String
}
