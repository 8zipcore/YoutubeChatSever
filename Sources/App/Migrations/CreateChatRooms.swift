//
//  File.swift
//  
//
//  Created by 홍승아 on 7/10/24.
//

import Fluent

struct CreateChatRooms: AsyncMigration{
    func prepare(on database: Database) async throws {
        try await database.schema("chat_rooms")
            .id()
            .field("name", .string)
            .field("description", .string)
            .field("image", .string)
            .field("background_image", .string)
            .field("room_type", .int)
            .field("enter_code", .string)
            .field("host_id", .uuid)
            .field("participant_ids", .array(of: .uuid))
            .field("chat_options", .array(of: .int))
            .field("categories", .array(of: .string))
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.schema("chat_rooms").delete()
    }
}
