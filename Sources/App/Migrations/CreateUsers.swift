//
//  CreateUsers.swift
//
//
//  Created by 홍승아 on 5/15/24.
//

import Fluent
// (Id, name, description, image, backgroundImage, followingIds)
struct CreateUsers: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("name", .string)
            .field("description", .string)
            .field("image", .string)
            .field("background_image", .string)
            .field("following_ids", .array(of: .uuid))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
