//
//  CategoryManger.swift
//
//
//  Created by 홍승아 on 8/19/24.
//


import Vapor
import Fluent

actor CategoryManager{
    static let shared = CategoryManager()
    
    func addCategories(categories: [String], chatRoomId: UUID, req: Request) async throws {
        for category in categories {
            if let data = try await Category.query(on: req.db).filter(\.$name == category).first(){
                data.count += 1
                data.chatRoomIds.append(chatRoomId)
                try await data.update(on: req.db)
            } else {
                let data = Category(name: category, count: 1, chatRoomIds: [chatRoomId])
                try await data.save(on: req.db)
            }
        }
    }
    
    func deleteCategories(categories: [String], chatRoomId: UUID, req:Request) async throws {
        for category in categories {
            if let data = try await Category.query(on: req.db).filter(\.$name == category).first(),
               let index = data.chatRoomIds.firstIndex(of: chatRoomId){
                data.count -= 1
                if data.count == 0 {
                    try await data.delete(on: req.db)
                } else {
                    data.chatRoomIds.remove(at: index)
                    try await data.update(on: req.db)
                }
            }
        }
    }
    
    func fetchTop5Categories(req: Request) async throws -> [String]{
        let categories = try await Category.query(on: req.db)
                                           .sort(\.$count, .ascending)
                                           .range(0..<5)
                                           .all()
                                           .map{
                                               return $0.name
                                           }
        
        return categories
    }
    
    func fetchChatRoomIds(category: String, req: Request) async throws -> [UUID]{
        let response = try await Category.query(on: req.db).filter(\.$name == category).first().map{
            return $0.chatRoomIds
        }
        return response ?? []
    }
}
