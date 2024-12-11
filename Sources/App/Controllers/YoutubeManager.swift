//
//  YoutubeManger.swift
//  
//
//  Created by 홍승아 on 8/1/24.
//

import Foundation
import Fluent
import SQLKit
import Vapor
import PostgresKit

class YoutubeManager{
    static let shared = YoutubeManager()
    
    func createYoutubeTable(_ chatRoomId:UUID, _ req: Request)async throws {
        let _ = try await req.db.schema("\(chatRoomId.uuidString)_youtube")
                    .field("id", .uuid)
                    .field("youtube_id", .string)
                    .field("user_id", .uuid)
                    .field("title", .string)
                    .field("uploader", .string)
                    .field("thumbnail", .string)
                    .field("duration", .double)
                    .field("start_time", .double)
                    .field("end_time", .double)
                    .field("upload_time", .double)
                    .create()
    }
    
    func dropYoutubeTable(_ chatRoomId:UUID, _ req: Request)async throws {
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(chatRoomId.uuidString)_youtube\""
        
        let query = SQLQueryString("DROP TABLE \(unsafeRaw: scheme)")

        let _ = db.raw(query).run()
            .flatMapErrorThrowing { error in
                // SQL 쿼리 실행 오류 처리
                print(String(reflecting: error))
                throw Abort(.internalServerError, reason: "Failed to execute query: \(error)")
            }
    }
    
    func fetchVideos(_ chatRoomId: UUID, _ req: Request) async throws -> [Video]{
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(chatRoomId.uuidString)_youtube\""
        let query = SQLQueryString("SELECT * FROM \(unsafeRaw: scheme)")

        var response = try await db.raw(query).all(decoding: Video.self).sorted(by: { $0.uploadTime < $1.uploadTime})
        
        let currentTime = Date().timeIntervalSince1970
        
        var deleteIdArray: [UUID] = []
        
        for index in response.indices {
            if response[index].endTime < currentTime{
                try await deleteVideo(chatRoomId, response[index].id!, req)
                deleteIdArray.append(response[index].id!)
            }
        }
        
        let deleteIdSet = Set(deleteIdArray)
        response = response.filter { !deleteIdSet.contains($0.id!) }
        
        print("✅ video data 블러오기 성공")
        
        return response
    }
    
    func saveVideo(_ chatRoomId: UUID, _ video:Video,_ req: Request) async throws{
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(chatRoomId.uuidString)_youtube\""
        let query = SQLQueryString("INSERT INTO \(unsafeRaw: scheme) (id, youtube_id, user_id, title, uploader, thumbnail, duration, start_time, end_time, upload_time) VALUES (\(bind: video.id), \(bind: video.youtubeId), \(bind: video.userId), \(bind: video.title), \(bind: video.uploader), \(bind: video.thumbnail), \(bind: video.duration), \(bind: video.startTime), \(bind: video.endTime), \(bind: video.uploadTime))")

        let _ = db.raw(query).run()
            .flatMapErrorThrowing { error in
                // SQL 쿼리 실행 오류 처리
                print(String(reflecting: error))
                throw Abort(.internalServerError, reason: "Failed to execute query: \(error)")
            }

        print("✅ video data 저장 성공")
    }
    
    func updateStartTime(_ data: StartVideoRequestData, _ req: Request) async throws -> ResponseCode{
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(data.chatRoomId.uuidString)_youtube\""
        
        let query = SQLQueryString("UPDATE \(unsafeRaw: scheme) SET start_time = \(unsafeRaw: String(data.startTime)) WHERE id = '\(unsafeRaw: data.videoId.uuidString)'")
    
        let _ = db.raw(query).run()
            .flatMapErrorThrowing { error in
                // SQL 쿼리 실행 오류 처리
                print(String(reflecting: error))
                throw Abort(.internalServerError, reason: "Failed to execute query: \(error)")
            }
        
        return .success
    }
    
    func deleteVideo(_ chatRoomId: UUID, _ videoId: UUID, _ req: Request) async throws {
        let db = req.db as! SQLDatabase
        
        try await db.delete(from: "\(chatRoomId.uuidString)_youtube" )
            .orWhere("id", .equal, videoId)
            .run()
    }
    
    func deleteVideo(_ data: DeleteVideoRequestData, _ req: Request) async throws -> Video? {
        var videos = try await fetchVideos(data.chatRoomId, req)
        
        var deleteVideoIndex = -1
        var endTime: Double = .zero
        let currentTime = Date().timeIntervalSince1970
        
        for index in videos.indices{
            if videos[index].id == data.videoId {
                deleteVideoIndex = index
                if index == 0 {
                    endTime = currentTime
                } else {
                    endTime = videos[index - 1].endTime
                }
            }
            
            if index > deleteVideoIndex && deleteVideoIndex != -1{
                videos[index].startTime = endTime
                videos[index].endTime = endTime + videos[index].duration
            }
        }
        
        var result: Video? = nil
        
        if deleteVideoIndex > -1 {
            result = videos[deleteVideoIndex]
            videos.remove(at: deleteVideoIndex)
        }
        let db = req.db as! SQLDatabase
        
        let scheme = "\"\(data.chatRoomId.uuidString)_youtube\""
        
        let query = SQLQueryString("""
        DELETE FROM \(unsafeRaw: scheme);
        """)
        
        let _ = db.raw(query).run()
            .flatMapErrorThrowing { error in
                // SQL 쿼리 실행 오류 처리
                print(String(reflecting: error))
                throw Abort(.internalServerError, reason: "Failed to execute query: \(error)")
            }
        
        // INSERT 쿼리 생성
          var insertQuery = db.insert(into: "\(data.chatRoomId.uuidString)_youtube")
              .columns("id", "youtube_id", "user_id", "title", "uploader", "thumbnail", "duration", "start_time", "end_time", "upload_time")

          // 각 비디오 데이터 추가
          for video in videos {
              insertQuery = insertQuery.values(
                  SQLBind(video.id),
                  SQLBind(video.youtubeId),
                  SQLBind(video.userId),
                  SQLBind(video.title),
                  SQLBind(video.uploader),
                  SQLBind(video.thumbnail),
                  SQLBind(video.duration),
                  SQLBind(video.startTime),
                  SQLBind(video.endTime),
                  SQLBind(video.uploadTime)
              )
          }
    
        let _ = insertQuery.run()
            .flatMapErrorThrowing { error in
                // SQL 쿼리 실행 오류 처리
                print(String(reflecting: error))
                throw Abort(.internalServerError, reason: "Failed to execute query: \(error)")
            }
        
        return result
    }
    
    func fetchVideo(_ data: AddVideoRequestData, _ req: Request) async throws -> Video?{
        var id = ""
        
        if let youtubeURLComponents = URLComponents(string: data.url){
            let path = youtubeURLComponents.path
            // 1. https://www.youtube.com/watch?v=6UwinUgq054
            if path == "/watch"{
                if let queryItems = youtubeURLComponents.queryItems{
                    id = queryItems.first?.value ?? ""
                }
            } else { // 2. https://youtu.be/6UwinUgq054?feature=shared
                id = String(path.dropFirst())
            }
        }
        
        
        
        // 요청 보낼 URL 생성
        var urlComponents = URLComponents(string: "https://youtube.googleapis.com/youtube/v3/videos")!
        let apiKey = Environment.get("YOUTUBE_API_KEY")
        
        urlComponents.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails"),
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "key", value: apiKey ?? "AIzaSyDsPCM-xZ1WMJwltr5zbjSkLZE2bOe9h0o")
        ]
        
        guard let response = try await req.client.get(URI(string: urlComponents.string!)).body,
              let json = try JSONSerialization.jsonObject(with: response) as? [String : Any] else { throw Abort(.badRequest)}
        
        if let items = json["items"] as? [[String:Any]], items.count > 0{
            if let contentDetail = items[0]["contentDetails"] as? [String:Any], let snippet = items[0]["snippet"] as? [String:Any]{
                if let thumbnails = snippet["thumbnails"] as? [String:Any], let thumbnail = thumbnails["medium"] as? [String:Any]{
                    let video = Video(id: UUID(), youtubeId: id, userId: data.userId, title: snippet["title"] as? String ?? "-", uploader: snippet["channelTitle"] as? String ?? "-", thumbnail: thumbnail["url"] as? String ?? "-", duration: parseYouTubeDuration(duration: contentDetail["duration"] as? String ?? "0"), startTime: 0, endTime: 0, uploadTime: Date().timeIntervalSince1970)
                    return video
                }
            }
        }
        return nil
    }
    
    func parseYouTubeDuration(duration: String) -> Double {
        let regex = try! NSRegularExpression(pattern: "^PT(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?$", options: [])
        let nsDuration = duration as NSString
        let matches = regex.matches(in: duration, options: [], range: NSRange(location: 0, length: nsDuration.length))
        
        if let match = matches.first {
            let hours = match.range(at: 1).location != NSNotFound ? nsDuration.substring(with: match.range(at: 1)) : "0"
            let minutes = match.range(at: 2).location != NSNotFound ? nsDuration.substring(with: match.range(at: 2)) : "0"
            let seconds = match.range(at: 3).location != NSNotFound ? nsDuration.substring(with: match.range(at: 3)) : "0"
            
            // return "\(hours) hour(s), \(minutes) minute(s), \(seconds) second(s)"
            return Double(hours)! * 3600 + Double(minutes)! * 60 + Double(seconds)!
        }
        
        return 0
    }
    
}
