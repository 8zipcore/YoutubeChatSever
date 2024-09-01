//
//  ReqeustData.swift
//
//
//  Created by 홍승아 on 7/22/24.
//

import Vapor

struct YoutubeRequestData: Content{
    var url: String
}

struct EnterChatRoomData: Codable{
    var chatRoomId: UUID
    var enterCode: String
    var userId: UUID
}

struct ChatRoomRequestData: Codable{
    var chatRoomId: UUID
    var userId: UUID
}

struct FetchVideoRequestData: Content{
    var chatRoomId: UUID
    var userId: UUID
}

struct AddVideoRequestData: Content{
    var chatRoomId: UUID
    var userId: UUID
    var url: String
}

struct StartVideoRequestData: Content{
    var chatRoomId: UUID
    var videoId: UUID
    var startTime: Double
}

struct DeleteVideoRequestData: Content{
    var chatRoomId: UUID
    var videoId: UUID
}

struct SearchChatRoomData: Content{
    var searchTerm: String
    var chatOptions: [ChatOption]
}
