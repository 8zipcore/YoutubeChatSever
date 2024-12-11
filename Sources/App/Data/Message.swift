//
//  File.swift
//  
//
//  Created by 홍승아 on 7/10/24.
//

import Vapor

enum ChatOption: Int, Codable{
    case videoAddAllowed
    case searchAllowed
    case password
}

enum MessageType:Int, Codable{
    case text, image, addVideo, deleteVideo, enter, leave, reconnect
}

struct Message: Content{
    var id: UUID?
    var chatRoomId: UUID
    var senderId: UUID
    var messageType: MessageType
    var text: String = ""
    var timestamp: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatRoomId = "chatroom_id"
        case senderId = "sender_id"
        case messageType = "type"
        case text
        case timestamp
    }
}

