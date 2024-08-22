//
//  GroupChat.swift
//
//
//  Created by 홍승아 on 7/18/24.
//

import Foundation
import Vapor

struct UserWebsocket{
    var id: UUID
    var participants: [UUID: WebSocket]
}
