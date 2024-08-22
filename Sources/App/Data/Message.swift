//
//  File.swift
//  
//
//  Created by 홍승아 on 7/10/24.
//

import Vapor

enum ChatOption: Int, Codable{
    case anonymous
    case videoAddDenied
    case privateRoom
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
    var timestamp: TimeInterval?
    var isRead: Bool
}

