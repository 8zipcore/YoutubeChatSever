//
//  Video.swift
//
//
//  Created by 홍승아 on 8/1/24.
//

import Vapor
// id ( 그 고유번호 ), 제목, 올린사람이름, 썸네일, 시간, 시작시간, 종료시간
struct Video: Content{
    var id: UUID?
    var youtubeId: String
    var userId: UUID
    var title: String
    var uploader: String
    var thumbnail: String
    var duration: Double
    var startTime: Double
    var endTime: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case youtubeId = "youtube_id"
        case userId = "user_id"
        case title
        case uploader
        case thumbnail
        case duration
        case startTime = "start_time"
        case endTime = "end_time"
    }
}
