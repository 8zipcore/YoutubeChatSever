//
//  MessageManager.swift
//
//
//  Created by 홍승아 on 7/18/24.
//

import Foundation
import Fluent
import SQLKit
import Vapor

actor MessageManager{
    static let shared = MessageManager()
    
    var userWebSocket: [UUID: UserWebsocket] = [:]
  
    func addWebSocket(_ data: Message,_ req: Request, _ socket: WebSocket){
        if userWebSocket[data.chatRoomId] == nil{
            userWebSocket[data.chatRoomId] = UserWebsocket(id: data.chatRoomId,
                                                    participants: [data.senderId:socket])
        } else {
            userWebSocket[data.chatRoomId]!.participants[data.senderId] = socket
        }
    }
    
    func removeWebSocket(_ data: Message,_ req: Request, _ socket: WebSocket){
        userWebSocket[data.chatRoomId]!.participants.removeValue(forKey: data.senderId)
        
        if userWebSocket[data.chatRoomId]!.participants.isEmpty {
            userWebSocket.removeValue(forKey: data.chatRoomId)
        }
    }
    
    func createGroupChatTable(_ chatRoomId:UUID, _ req: Request)async throws {
        let _ = try await req.db.schema(chatRoomId.uuidString)
                    .id()
                    .field("groupchat_id", .uuid)
                    .field("sender_id", .uuid)
                    .field("type", .int8)
                    .field("message", .string)
                    .field("image", .string)
                    .field("timestamp", .double)
                    .create()
    }
    
    func dropGroupChatTable(_ chatRoomId:UUID, _ req: Request)async throws {
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(chatRoomId.uuidString)\""
        
        let query = SQLQueryString("DROP TABLE \(unsafeRaw: scheme)")

        let _ = db.raw(query).run()
            .flatMapErrorThrowing { error in
                // SQL 쿼리 실행 오류 처리
                print(String(reflecting: error))
                throw Abort(.internalServerError, reason: "Failed to execute query: \(error)")
            }
    }
    
    func addMessage(_ data: Message, _ req: Request){
        Task{
            var message = data
            var senderName = ""
            
            if message.messageType == .video || message.messageType == .enter || message.messageType == .leave {
                // 익명일 때
                if let chatRoom = try await ChatRoom.find(data.chatRoomId, on: req.db), chatRoom.chatOptions.contains(ChatOption.anonymous.rawValue){
                    senderName = "익명\(chatRoom.participantIds.count)"
                } else {
                    senderName = try await User.find(message.senderId, on: req.db).flatMap{
                        return $0.name
                    } ?? ""
                }
            }
            
            switch message.messageType{
            case .text: fallthrough
            case .image: break
            case .video:
                message.text = "\(senderName)님이 비디오를 추가하셨습니다."
                break
            case .enter:
                message.text = "\(senderName)님이 입장하셨습니다."
            case .leave:
                message.text = "\(senderName)님이 퇴장하셨습니다."
            }
            
            message.timestamp = TimeInterval()
            
            try await saveMessage(message, req)
            try await sendData(message.chatRoomId, .message, message)
        }
    }
    
    func saveMessage(_ data:Message,_ req: Request) async throws{
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(data.chatRoomId)\""
        let query = SQLQueryString("INSERT INTO \(unsafeRaw: scheme) (id, groupchat_id, sender_id, type, message, image, timestamp) VALUES (\(bind: UUID()), \(bind: data.chatRoomId), \(bind: data.senderId), \(bind: data.messageType), \(bind: data.text), \(bind: data.image), \(bind: TimeInterval()))")

        let _ = db.raw(query).run()
            .flatMapErrorThrowing { error in
                // SQL 쿼리 실행 오류 처리
                print(String(reflecting: error))
                throw Abort(.internalServerError, reason: "Failed to execute query: \(error)")
            }

        print("data 저장 성공")
    }
    /*
    func sendMessage(_ data: Message) async throws{
        let jsonData = try JSONEncoder().encode(data)
        
        if let userWebSocket = userWebSocket[data.chatRoomId]{
            for websocket in userWebSocket.participants.values{
                websocket.send(jsonData)
            }
        }
    }
    */
    
    func sendData<T: Codable>(_ id: UUID, _ type: SendDataType, _ data: T) async throws{
        let encodeData = try JSONEncoder().encode(data)
        let sendData = SendData(type: type, data: encodeData)
        let jsonData = try JSONEncoder().encode(sendData)
        if self.userWebSocket[id] != nil{
            for websocket in self.userWebSocket[id]!.participants.values{
                websocket.send(jsonData)
            }
        }
    }
}
