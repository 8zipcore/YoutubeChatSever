//
//  File.swift
//  
//
//  Created by 홍승아 on 7/11/24.
//

import Foundation
import Fluent
import SQLKit
import Vapor
import MultipartKit

struct ChatController: RouteCollection{
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let chat = routes.grouped("chat")
        
        chat.grouped("fetch").get(use: { try await self.fetchAllChatRoom(req: $0)})
        
        chat.grouped("create").post(use: { try await self.create(req: $0) })
        chat.grouped("update").post(use: { try await self.update(req: $0) })
        chat.grouped("uploadImage").post(use: { try await self.uploadImage(req: $0) } )
        chat.grouped("enter").post(use: { try await self.enterChatRoom(req: $0)} )
        chat.grouped("leave").post(use: { try await self.leaveChatRoom(req: $0)})
        chat.grouped("find").post(use: { try await self.findChatRoom(req: $0)})
        chat.grouped("quit").post(use: { try await self.quitChatRoom(req: $0)} )
        
        chat.grouped("fetchChats").post(use: { try await self.fetchChats(req: $0)} )
        
        chat.grouped("search").post(use: { try await self.searchChatRoom(req: $0)})
        
        chat.grouped("fetchVideos").post(use: { try await self.fetchVideos(req:$0) })
        chat.grouped("updateStartTime").post(use: { try await self.updateStartTime(req:$0) })
        
        chat.webSocket("message"){ req, ws in self.webSocket(req: req, ws: ws) }
    }
    
    func webSocket(req: Request, ws: WebSocket){
        print("⭐️ WebSocket connected")
        
        // 메시지 수신 핸들러
        ws.onBinary { ws, data in
            do{
                let jsonDecoder = JSONDecoder()
                let message = try jsonDecoder.decode(Message.self, from: data)
                let type = message.messageType
                Task{
                    if type == .enter {
                        await MessageManager.shared.addWebSocket(message, req, ws)
                    } else if type == .leave {
                        await MessageManager.shared.removeWebSocket(message, req, ws)
                    }
                
                    if type == .addVideo{
                        let data = AddVideoRequestData(chatRoomId: message.chatRoomId, userId: message.senderId, url: message.text)
                        let video = try await self.addVideo(data: data, req: req)
                        try await MessageManager.shared.sendData(data.chatRoomId, .addVideo, video)
                    } else if type == .deleteVideo{
                        let data = DeleteVideoRequestData(chatRoomId: message.chatRoomId, videoId: UUID(message.text) ?? UUID())
                        let video = try await self.deleteVideo(data: data, req: req)
                        try await MessageManager.shared.sendData(data.chatRoomId, .deleteVideo, video)
                    } else if type == .reconnect {
                        await MessageManager.shared.reconnectWebSocket(message, req, ws)
                    } else {
                        await MessageManager.shared.addMessage(message, req)
                    }
                }
                print("Received : \(message)")
            } catch {
                
            }
        }

        // 웹소켓 닫기 핸들러
        ws.onClose.whenComplete { result in
            print("⭐️ WebSocket closed")
        }
    }
    
    func create(req: Request) async throws -> ChatRoomData{
        let chatRoom = try req.content.decode(ChatRoom.self)

        try await chatRoom.save(on: req.db)
        if let id = chatRoom.id{
            try await MessageManager.shared.createGroupChatTable(id, req)
            try await YoutubeManager.shared.createYoutubeTable(id, req)
            try await CategoryManager.shared.addCategories(categories: chatRoom.categories, chatRoomId: id, req: req)
        }
        
        return try await chatRoomToChatRoomData(chatRoom, req: req)

/*
        try await chatRoom.save(on: req.db)
        if let id = chatRoom.id{
            try await MessageManager.shared.createGroupChatTable(id, req)
            try await YoutubeManager.shared.createYoutubeTable(id, req)
            try await CategoryManager.shared.addCategories(categories: chatRoom.categories, chatRoomId: id, req: req)
            if let imageData = data.image{
                chatRoom.image = try await SupabaseManager.shared.uploadImage(imageData: imageData, fileName: "\(id.uuidString)_chatRoom", path: "chatinfo", req: req)
                try await chatRoom.save(on: req.db)
            }
        }
        
        return try await chatRoomToChatRoomData(ChatRoom(name: "", description: "", image: "", enterCode: "", hostId: UUID(), participantIds: [UUID()], allParticipantsIds: [UUID()], chatOptions: [], categories: [], lastChatTime: 0), req: req)
 */
    }

    func update(req: Request) async throws -> ChatRoomData{
        let newChatRoom = try req.content.decode(ChatRoom.self)
        if let chatRoom = try await ChatRoom.find(newChatRoom.id, on: req.db), let id = chatRoom.id{
            // 이름, 설명, 이미지, 참여코드, chatoption,
            chatRoom.name = newChatRoom.name
            chatRoom.description = newChatRoom.description
            chatRoom.chatOptions = newChatRoom.chatOptions
            if newChatRoom.chatOptions.contains(ChatOption.password.rawValue){
                chatRoom.enterCode = newChatRoom.enterCode
            }
            // 카테고리
            try await CategoryManager.shared.deleteCategories(categories: chatRoom.categories, chatRoomId: id, req: req)
            try await CategoryManager.shared.addCategories(categories: newChatRoom.categories, chatRoomId: id, req: req)
            
            try await chatRoom.save(on: req.db)
            
            return try await chatRoomToChatRoomData(chatRoom, req: req)
        }
        return try await chatRoomToChatRoomData(newChatRoom, req: req)
    }
    
    func uploadImage(req: Request) async throws -> ResponseWithStringData{
        let data = try req.content.decode(ChatRoomImageData.self)
        let chatRoom = try await ChatRoom.find(UUID(data.id), on: req.db)
        
        if let chatRoom = chatRoom, let id = chatRoom.id{
            let fileName = "\(id.uuidString)"
            let path = "chatinfo"
            
            if let imageData = data.image{
                if chatRoom.image.count > 0 { // update
                    try await SupabaseManager.shared.updateImage(imageData: imageData, fileName: fileName, path: path, req: req)
                } else { // upload
                    chatRoom.image = try await SupabaseManager.shared.uploadImage(imageData: imageData, fileName: fileName, path: path, req: req)
                }
            } else { //delete
                if chatRoom.image.count > 0{
                    try await SupabaseManager.shared.deleteImage(fileName: fileName, path: path, req: req)
                }
            }
            
            try await chatRoom.save(on: req.db)
            
            return ResponseWithStringData(responseCode: .success, string: chatRoom.image)
        }
        return ResponseWithStringData(responseCode: .failure, string: "")
    }

    func findChatRoom(req: Request) async throws -> ChatRoomData{
        let enterChatData = try req.content.decode(ChatRoomRequestData.self)
        let chatRoom = try await ChatRoom.find(enterChatData.chatRoomId, on: req.db).flatMap{ return $0 }
        return try await chatRoomToChatRoomData(chatRoom!,  req: req)
    }
    
    func enterChatRoom(req: Request) async throws -> ChatRoomResponseData{
        let enterChatData = try req.content.decode(EnterChatRoomData.self)
        let chatRoom = try await ChatRoom.find(enterChatData.chatRoomId, on: req.db).map{
            $0.participantIds.append(enterChatData.userId)
            if $0.allParticipantIds.filter({ $0 == enterChatData.userId }).first == nil {
                $0.allParticipantIds.append(enterChatData.userId)
            }
            return $0
        }
        
        if let chatRoom = chatRoom {
            if (chatRoom.chatOptions.contains(ChatOption.password.rawValue) && chatRoom.enterCode != enterChatData.enterCode){
                return ChatRoomResponseData(responseCode: .failure, chatRoom: nil)
            }
            let _ = try await chatRoom.update(on: req.db)
            let chatRoomData = try await chatRoomToChatRoomData(chatRoom, req: req)
            
            if let enterUser = try await User.find(enterChatData.userId, on: req.db){
                let participantData = ParticipantData(type: .enter, user: enterUser)
                enterUser.image = ""
                try await MessageManager.shared.sendData(chatRoom.id!, .participant, enterUser)
            }
            
            return ChatRoomResponseData(responseCode: .success, chatRoom: chatRoomData)
        } else {
            return ChatRoomResponseData(responseCode: .invalid, chatRoom: nil)
        }
    }
    
    func leaveChatRoom(req: Request) async throws -> ResponseData {
        let enterChatData = try req.content.decode(ChatRoomRequestData.self)
        if let chatRoom = try await ChatRoom.find(enterChatData.chatRoomId, on: req.db){
            if let index = chatRoom.participantIds.firstIndex(of: enterChatData.userId){
                
                chatRoom.participantIds.remove(at: index)
                                
                if chatRoom.participantIds.isEmpty, let id = chatRoom.id{
                    let _ = try await chatRoom.delete(on: req.db)
                    try await MessageManager.shared.dropGroupChatTable(id, req)
                    try await YoutubeManager.shared.dropYoutubeTable(id, req)
                    try await CategoryManager.shared.deleteCategories(categories: chatRoom.categories, chatRoomId: id, req: req)
                } else {
                    if enterChatData.userId == chatRoom.hostId {
                        chatRoom.hostId = chatRoom.participantIds[0]
                    }
                    let _ = try await chatRoom.update(on: req.db)
                }
                /*
                if let leaveUser = try await User.find(enterChatData.userId, on: req.db){
                    let participantData = ParticipantData(type: .leave, user: leaveUser)
                    try await MessageManager.shared.sendData(chatRoom.id!, .participant, leaveUser)
                }*/
                
                return ResponseData(responseCode: .success)
            }
        }
        return ResponseData(responseCode: .failure)
    }
    
    func quitChatRoom(req: Request) async throws -> ResponseData {
        let enterChatData = try req.content.decode(ChatRoomRequestData.self)
        if let chatRoom = try await ChatRoom.find(enterChatData.chatRoomId, on: req.db){
            if let index = chatRoom.participantIds.firstIndex(of: enterChatData.userId){
                chatRoom.participantIds.remove(at: index)
                let _ = try await chatRoom.update(on: req.db)
                return ResponseData(responseCode: .success)
            }
        }
        return ResponseData(responseCode: .failure)
    }
    
    func fetchAllChatRoom(req: Request) async throws -> [ChatRoomData]{
        let chatRooms = try await ChatRoom.query(on: req.db).all().filter{
            $0.chatOptions.contains(ChatOption.searchAllowed.rawValue)
        }
        var chatRoomDatas: [ChatRoomData] = []
        for chatRoom in chatRooms {
            await chatRoomDatas.append(try chatRoomToChatRoomData(chatRoom, req: nil))
        }
        return chatRoomDatas
    }
    
    func fetchParticipants(id: UUID, req: Request) async throws -> [User]{
        let chatRoom = try await ChatRoom.find(id, on: req.db).map{ return $0 }
        
        var users: [User] = []
        
        if let chatRoom = chatRoom{
            let participantIds = chatRoom.allParticipantIds
            for id in participantIds {
                if let user = try await User.find(id, on: req.db) {
                    /*if chatRoom.chatOptions.contains(ChatOption.anonymous.rawValue){
                        user.name = "익명\(users.count + 1)"
                    }*/
                    users.append(user)
                }
            }
        }
        return users
    }
    
    func chatRoomToChatRoomData(_ chatRoom: ChatRoom, req: Request?) async throws -> ChatRoomData{
        var participants: [User] = []
        if let req = req, let id = chatRoom.id {
            let users = try await fetchParticipants(id: id, req: req)
            participants = users
        }
        return ChatRoomData(id: chatRoom.id, name: chatRoom.name, description: chatRoom.description, image: chatRoom.image, enterCode: chatRoom.enterCode, hostId: chatRoom.hostId, participantIds: chatRoom.participantIds, allParticipantIds: chatRoom.allParticipantIds, participants: participants, chatOptions: chatRoom.chatOptions, categories: chatRoom.categories, lastChatTime: chatRoom.lastChatTime)
    }
    
    func fetchChats(req: Request) async throws -> [Message] {
        let enterChatData = try req.content.decode(ChatRoomRequestData.self)
        
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(enterChatData.chatRoomId.uuidString)\""
        let query = SQLQueryString("SELECT * FROM \(unsafeRaw: scheme)")
        let response = try await db.raw(query).all(decoding: Message.self)
        
        return response
    }

}
// MARK: - Search
extension ChatController{
    func searchChatRoom(req: Request) async throws -> [ChatRoomData]{
        let chatRooms = try await fetchAllChatRoom(req: req)
        let data = try req.content.decode(SearchChatRoomData.self)
        let chatOptions = data.chatOptions.map{ return $0.rawValue }
        return chatRooms.filter({($0.name.contains(data.searchTerm) || $0.description.contains(data.searchTerm)) && $0.chatOptions.contains(chatOptions)})
    }
}
// MARK: - Video
extension ChatController{
    func fetchVideos(req: Request) async throws -> [Video]{
        let data = try req.content.decode(FetchVideoRequestData.self)
        return try await YoutubeManager.shared.fetchVideos(data.chatRoomId, req)
    }
    
    func addVideo(data: AddVideoRequestData, req: Request) async throws -> VideoResponseData{
        if var video = try await YoutubeManager.shared.fetchVideo(data, req){
            let videos = try await YoutubeManager.shared.fetchVideos(data.chatRoomId, req)
            if videos.count == 0 {
                video.startTime = Date().timeIntervalSince1970
            } else {
                video.startTime = videos.last?.endTime ?? 0
            }
            video.endTime = video.startTime + video.duration
            try await YoutubeManager.shared.saveVideo(data.chatRoomId, video, req)
            return VideoResponseData(responseCode: .success, video: video)
        }
        return VideoResponseData(responseCode: .failure)
    }
    
    func deleteVideo(data: DeleteVideoRequestData, req: Request) async throws -> VideoResponseData{
        let video = try await YoutubeManager.shared.deleteVideo(data, req)
        if let video = video {
            return VideoResponseData(responseCode: .success, video: video)
        }
        return VideoResponseData(responseCode: .failure)
    }
    
    func updateStartTime(req: Request) async throws -> ResponseData{
        let data = try req.content.decode(StartVideoRequestData.self)
        let response = try await YoutubeManager.shared.updateStartTime(data, req)
        return ResponseData(responseCode: response)
    }
}
// MARK: - 코드
/*
extension ChatController{
    func generateEnterCode() -> String{
        let length = 8
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func enterCodeArray(req: Request) async throws -> [String]{
        return try await ChatRoom.query(on: req.db).all().map{
            return $0.enterCode
        }
    }
}
*/
