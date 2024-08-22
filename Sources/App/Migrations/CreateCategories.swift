//
//  File.swift
//  
//
//  Created by 홍승아 on 8/19/24.
//

import Fluent

struct CreateCategories: AsyncMigration{
    func prepare(on database: Database) async throws {
        try await database.schema("categories")
            .id()
            .field("name", .string)
            .field("count", .int)
            .field("chat_room_ids", .array(of: .uuid))
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.schema("categories").delete()
    }
}
