//
//  CategoryController.swift
//
//
//  Created by 홍승아 on 8/19/24.
//

import Fluent
import Vapor

struct CategoryController: RouteCollection{
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let search = routes.grouped("category")
        
        search.grouped("fetch").get(use: { try await self.fetchHotCategories(req: $0)})
        search.grouped("fetchChatRooms").post(use: { try await self.fetchChatRooms(req: $0)})
    }
    
    func fetchHotCategories(req: Request) async throws -> [String]{
        let categories = try await CategoryManager.shared.fetchTop5Categories(req: req)
        return categories
    }
    
    func fetchChatRooms(req: Request) async throws -> [ChatRoomData] {
        let data = try req.content.decode(String.self)
        let chatRoomIds = try await CategoryManager.shared.fetchChatRoomIds(category: data, req: req)
        
        let chatRooms = try await ChatRoom.query(on: req.db)
                                            .filter(\.$id ~~ chatRoomIds) // '~~'는 배열에 포함되는지 확인
                                            .all()
        
        var chatRoomDatas: [ChatRoomData] = []
        for chatRoom in chatRooms{
            chatRoomDatas.append(try await chatRoomToChatRoomData(chatRoom, req: req))
        }
        
        return chatRoomDatas
    }
    
    func fetchParticipants(id: UUID, req: Request) async throws -> [User]{
        let chatRoom = try await ChatRoom.find(id, on: req.db).map{ return $0 }
        
        var users: [User] = []
        
        if let chatRoom = chatRoom{
            let participantIds = chatRoom.participantIds
            for id in participantIds {
                if let user = try await User.find(id, on: req.db) {
                    if chatRoom.chatOptions.contains(ChatOption.anonymous.rawValue){
                        user.name = "익명\(users.count + 1)"
                    }
                    users.append(user)
                }
            }
        }
        return users
    }
    
    func chatRoomToChatRoomData(_ chatRoom: ChatRoom, req: Request?) async throws -> ChatRoomData{
        if let req = req, let id = chatRoom.id {
            let users = try await fetchParticipants(id: id, req: req)
            return ChatRoomData(id: chatRoom.id, name: chatRoom.name, description: chatRoom.description, image: chatRoom.image, enterCode: chatRoom.enterCode, hostId: chatRoom.hostId, participantIds: chatRoom.participantIds, participants: users, chatOptions: chatRoom.chatOptions, categories: chatRoom.categories)
        } else {
            return ChatRoomData(id: chatRoom.id, name: chatRoom.name, description: chatRoom.description, image: chatRoom.image, enterCode: chatRoom.enterCode, hostId: chatRoom.hostId, participantIds: chatRoom.participantIds, participants: [], chatOptions: chatRoom.chatOptions, categories: chatRoom.categories)
        }
    }
}
