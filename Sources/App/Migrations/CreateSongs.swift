//
//  CreateSongs.swift
//
//
//  Created by 홍승아 on 5/2/24.
//

import Fluent

struct CreateSongs: Migration {
    
    func prepare(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        return database.schema("songs")
            .id()
            .field("title", .string, .required)
            .create()
    }
    
    func revert(on database: FluentKit.Database) -> EventLoopFuture<Void> {
        return database.schema("songs").delete()
    }  
}
