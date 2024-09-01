//
//  ChatRoomData.swift
//
//
//  Created by 홍승아 on 8/14/24.
//

import Vapor

struct ChatRoomData: Content{
    var id: UUID?
    var name: String
    var description: String
    var image: String
    var enterCode: String
    var hostId: UUID
    var participantIds: [UUID]
    var participants: [User] // ChatRoom과 다른 변수 !!
    var chatOptions: [Int]
    var categories: [String]
    var lastChatTime: Double
}
