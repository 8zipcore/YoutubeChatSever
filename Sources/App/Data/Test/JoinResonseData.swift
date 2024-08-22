//
//  File.swift
//  
//
//  Created by 홍승아 on 5/18/24.
//

import Vapor

struct IDValidationResponseData: Content{
    var code: IDValidationResponseCode
    var id: UUID?
    var text: String?
}
