//
//  ChatRoom.swift
//
//
//  Created by 홍승아 on 7/10/24.
//

import Foundation
import Fluent
import Vapor

final class ChatRoom: Model, Content, @unchecked Sendable {
    static let schema: String = "chat_rooms"
    // (Id, name, description, image, backgroundImage, roomType, enterCode, hostId, participantIds, options, categories) 
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "image")
    var image: String
    
    @Field(key: "enter_code")
    var enterCode: String
    
    @Field(key: "host_id")
    var hostId: UUID
    
    @Field(key: "participant_ids")
    var participantIds: [UUID]
    
    @Field(key: "chat_options")
    var chatOptions: [Int]
    
    @Field(key: "categories")
    var categories: [String]
    
    @Field(key: "last_chat_time")
    var lastChatTime: Double

    init() { }
    
    init(id: UUID? = nil, name: String, description: String, image: String, enterCode: String, hostId: UUID, participantIds: [UUID], chatOptions: [Int], categories: [String], lastChatTime: Double){
        self.id = id
        self.name = name
        self.description = description
        self.image = image
        self.enterCode = enterCode
        self.hostId = hostId
        self.participantIds = participantIds
        self.chatOptions = chatOptions
        self.categories = categories
        self.lastChatTime = lastChatTime
    }
}
