//
//  File.swift
//  
//
//  Created by 홍승아 on 7/2/24.
//

import Foundation
import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema: String = "users"

    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "image")
    var image: String
    
    @Field(key: "background_image")
    var backgroundImage: String
    
    /*@Field(key: "following_ids")
    var followingIds: [UUID]
    */
    init() { }
    
    init(id: UUID? = nil, name: String, description: String, image: String, backgroundImage: String){
        self.id = id
        self.name = name
        self.description = description
        self.image = image
        self.backgroundImage = backgroundImage
    }
    
}
                        
