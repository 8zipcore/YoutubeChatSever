//
//  File.swift
//  
//
//  Created by 홍승아 on 7/10/24.
//

import Vapor

enum ChatOption: Int, Codable{
    case videoAddDenied
    case searchAllowed
    case password
}

enum MessageType:Int, Codable{
    case text, image, video, enter, leave
}

struct Message: Content{
    var id: UUID?
    var chatRoomId: UUID
    var senderId: UUID
    var messageType: MessageType
    var text: String = ""
    var image: String?
    var timestamp: Double
    var isRead: Bool
}

