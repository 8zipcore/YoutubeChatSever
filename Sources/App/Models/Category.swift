//
//  Category.swift
//
//
//  Created by 홍승아 on 8/19/24.
//

import Foundation
import Fluent
import Vapor

final class Category: Model, Content, @unchecked Sendable {
    static let schema: String = "categories"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "count")
    var count: Int
    
    @Field(key: "chat_room_ids")
    var chatRoomIds: [UUID]
    
    init() { }
    
    init(id: UUID? = nil, name: String, count: Int, chatRoomIds: [UUID]){
        self.id = id
        self.name = name
        self.count = count
        self.chatRoomIds = chatRoomIds
    }
}

