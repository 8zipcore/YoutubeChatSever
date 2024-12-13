//
//  File.swift
//  
//
//  Created by 홍승아 on 7/22/24.
//

import Vapor

enum EnterCodeResponse: Int, Codable{
    case invalidCode, validCode, existing
}

enum SendDataType: Int, Codable{
    case message, addVideo, deleteVideo, participant
}

struct EnterChatResponseData: Content{
    var responseCode: EnterCodeResponse
    var chatRoom: ChatRoom?
}

enum ResponseCode: Int, Codable{
    case success, failure
}

enum EnterChatRoomResponseCode: Int, Codable{
    case success, failure, invalid
}

struct ResponseData: Content{
    var responseCode: ResponseCode
}

struct ResponseWithStringData: Content{
    var responseCode: ResponseCode
    var string: String
}

struct VideoResponseData: Codable{
    var responseCode: ResponseCode
    var video: Video?
}

struct SendData: Content{
    var type: SendDataType
    var data: Data
}

struct ChatRoomResponseData: Content{
    var responseCode: EnterChatRoomResponseCode
    var chatRoom: ChatRoomData?
}

struct ParticipantData: Content {
    var type: MessageType
    var user: User
}
