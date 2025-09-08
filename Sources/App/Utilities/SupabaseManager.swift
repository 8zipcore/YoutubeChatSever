//
//  SupabaseManager.swift
//
//
//  Created by 홍승아 on 12/11/24.
//

import Foundation
import Vapor

actor SupabaseManager{
    static let shared = SupabaseManager()
    
    var supabaseUrl: String = ""
    var supabaseKey: String = ""
    var bucketName: String = ""
    
    func setSupabase(supabaseUrl: String, supabaseKey: String, bucketName: String){
        self.supabaseUrl = supabaseUrl
        self.supabaseKey = supabaseKey
        self.bucketName = bucketName
    }
    
    func uploadImage(imageData: Data, fileName: String, path: String, req: Request) async throws -> String {
        let path = "public/\(path)/\(fileName).jpg"
        let urlString = "\(supabaseUrl)/storage/v1/object/\(bucketName)/\(path)"
        let file = File(name: fileName, data: imageData, fileName: fileName, contentType: "image/jpg")
        let formData = FormData(file: file)
        let responseCode = try await upload(req, urlString, from: formData)
         
        if responseCode == .success {
            return "\(supabaseUrl)/storage/v1/object/public/\(bucketName)/\(path)"
        } else {
            return ""
        }
        /* Supabase Package 사용 코드 */
        /*
        let supabase = SupabaseStorageClient(url: "\(supabaseUrl)/storage/v1", headers: [
            "authorization": supabaseKey,
        ])
        
        let path = "/public/\(path)/\(fileName).jpg"
        let file = File(name: fileName, data: imageData, fileName: fileName, contentType: "image/jpg")
        
        let _ = try await supabase.from(id: bucketName)
            .upload(path: path, file: file, fileOptions: nil)
        
        let publicURL = try supabase.from(id: bucketName)
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
         */
    }
    
    func updateImage(imageData: Data, fileName: String, path: String, req: Request) async throws{
        let path = "public/\(path)/\(fileName).jpg"
        let urlString = "\(supabaseUrl)/storage/v1/object/\(bucketName)/\(path)"
        let file = File(name: fileName, data: imageData, fileName: fileName, contentType: "image/jpg")
        let formData = FormData(file: file)
        let responseCode = try await update(req, urlString, from: formData)
         
        if responseCode == .success {
            print("✅ Update Success")
        } else {
            print("🌀 Update Fail")
        }
        /* Supabase Package 사용 코드 */
        /*
        let supabase = SupabaseStorageClient(url: "\(supabaseUrl)/storage/v1", headers: [
            "authorization": supabaseKey,
        ])
        
        let path = "public/\(path)/\(fileName).jpg"
        let file = File(name: fileName, data: imageData, fileName: fileName, contentType: "image/jpg")
        
        let _ = try await supabase.from(id: bucketName)
            .update(path: path, file: file, fileOptions: nil)
        print(path)
        */
    }
    
    func deleteImage(fileName: String, path: String, req: Request) async throws {
        let path = "public/\(path)/\(fileName).jpg"
        let urlString = "\(supabaseUrl)/storage/v1/object/\(bucketName)/\(path)"
        let parameters = ["prefixes": path]
        let responseCode = try await delete(req, parameters, urlString)
         
        if responseCode == .success {
            print("✅ Delete Success")
        } else {
            print("🌀 Delete Fail")
        }
        /* Supabase Package 사용 코드 */
        /*
        let supabase = SupabaseStorageClient(url: "\(supabaseUrl)/storage/v1", headers: [
            "authorization": supabaseKey,
        ])
        
        let path = "public/\(path)/\(fileName).jpg"
        
        let _ = try await supabase.from(id: bucketName).remove(paths: [path])
        print(path)
        print("✅ delete")
         */
    }
    
    private func upload(
        _ req: Request,
        _ urlString: String,
        from data: FormData
    ) async throws -> (ResponseCode) {
      try await withCheckedThrowingContinuation { continuation in
          req.client.post(URI(string: urlString)) { req in
              req.headers.bearerAuthorization = BearerAuthorization(token: supabaseKey)
              req.headers.contentType = HTTPMediaType(type: "multipart", subType: "form-data", parameters: ["boundary": data.boundary])
              req.body = data.body
          }.whenComplete { result in
              switch result {
              case .success(_):
                  continuation.resume(returning: .success)
              case .failure(let error):
                  print("Error: \(error)")
                  continuation.resume(returning: .failure)
              }
          }
      }
    }
    
    private func update(
        _ req: Request,
        _ urlString: String,
        from data: FormData
    ) async throws -> (ResponseCode) {
      try await withCheckedThrowingContinuation { continuation in
          req.client.put(URI(string: urlString)) { req in
              req.headers.bearerAuthorization = BearerAuthorization(token: supabaseKey)
              req.headers.contentType = HTTPMediaType(type: "multipart", subType: "form-data", parameters: ["boundary": data.boundary])
              req.body = data.body
          }.whenComplete { result in
              switch result {
              case .success(_):
                  continuation.resume(returning: .success)
              case .failure(let error):
                  print("Error: \(error)")
                  continuation.resume(returning: .failure)
              }
          }
      }
    }
    
    private func delete(
        _ req: Request,
        _ parameters: [String : String],
        _ urlString: String
    ) async throws -> (ResponseCode) {
        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
        var byteBuffer = ByteBufferAllocator().buffer(capacity: jsonData.count)
        byteBuffer.writeBytes(jsonData)
        
        return try await withCheckedThrowingContinuation { continuation in
            req.client.delete(URI(string: urlString)) { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: supabaseKey)
                req.body = byteBuffer
            }
            .whenComplete { result in
                switch result {
                case .success(_):
                    continuation.resume(returning: .success)
                case .failure(let error):
                    print("Error: \(error)")
                    continuation.resume(returning: .failure)
                }
            }
        }
    }
}
