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
    case message, video
}

struct EnterChatResponseData: Content{
    var responseCode: EnterCodeResponse
    var chatRoom: ChatRoom?
}

enum ResponseCode: Int, Codable{
    case success, failure
}

struct ResponseData: Content{
    var responseCode: ResponseCode
}

struct AddVideoResponseData: Content{
    var responseCode: ResponseCode
    var videos: [Video]
}

struct SendData: Content{
    var type: SendDataType
    var data: Data
}
