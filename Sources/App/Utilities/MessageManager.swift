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
    
    func reconnectWebSocket(_ data: Message, _ req: Request, _ socket: WebSocket){
        userWebSocket[data.chatRoomId]!.participants[data.senderId] = socket
    }
    
    func createGroupChatTable(_ chatRoomId:UUID, _ req: Request)async throws {
        let _ = try await req.db.schema(chatRoomId.uuidString)
                    .id()
                    .field("chatroom_id", .uuid)
                    .field("sender_id", .uuid)
                    .field("type", .int64)
                    .field("text", .string)
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
            var user: User?
            var senderName = ""
            
            if message.messageType == .addVideo || message.messageType == .enter || message.messageType == .leave {
                user = try await User.find(message.senderId, on: req.db)
                senderName = user?.name ?? ""
            }
            
            switch message.messageType{
            case .text: fallthrough
            case .image: break
            case .addVideo:
                message.text = "\(senderName)님이 비디오를 추가하셨습니다."
                break
            case .enter:
                message.text = "\(senderName)님이 입장하셨습니다."
            case .leave:
                message.text = "\(senderName)님이 퇴장하셨습니다."
            case .reconnect:
                break
            case .deleteVideo:
                break
            }
            
            message.timestamp = Date().timeIntervalSince1970
            
            try await saveMessage(message, req)
            try await sendData(message.chatRoomId, .message, message)
            print("✅ sendData : \(message.text)")
            
            // 채팅 시간 업데이트
            if [.text, .image, .addVideo].contains(message.messageType){
                let _ = try await ChatRoom.find(message.chatRoomId, on: req.db).flatMap{
                    $0.lastChatTime = message.timestamp
                    return $0.update(on: req.db)
                }
            }
            // 입장 시간 업데이트
            if [.enter, .leave].contains(message.messageType), let id = user?.id?.uuidString{
                if message.messageType == .enter{
                    let _ = try await ChatRoom.find(message.chatRoomId, on: req.db).flatMap{
                        $0.enterTimes[id] = message.timestamp
                        return $0.update(on: req.db)
                    }
                } else if message.messageType == .leave{
                    let _ = try await ChatRoom.find(message.chatRoomId, on: req.db).flatMap{
                        $0.enterTimes.removeValue(forKey: id)
                        return $0.update(on: req.db)
                    }
                }
            }
        }
    }
    
    func saveMessage(_ data:Message,_ req: Request) async throws{
        let db = req.db as! SQLDatabase

        let scheme = "\"\(data.chatRoomId)\""
        let query = SQLQueryString("INSERT INTO \(unsafeRaw: scheme) (id, chatroom_id, sender_id, type, text, timestamp) VALUES (\(bind: UUID()), \(bind: data.chatRoomId), \(bind: data.senderId), \(bind: data.messageType), \(bind: data.text), \(bind: data.timestamp))")

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
