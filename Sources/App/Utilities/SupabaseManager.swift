//
//  SupabaseManager.swift
//
//
//  Created by 홍승아 on 12/11/24.
//

import Foundation
import Vapor
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class SupabaseManager{
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
        
        guard let url = URL(string: "\(supabaseUrl)/storage/v1/object/\(bucketName)/\(path)") else { return "" }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue

        request.setValue(supabaseKey, forHTTPHeaderField: "authorization")
        
        let formData = FormData()
        formData.append(file: File(name: fileName, data: imageData, fileName: fileName, contentType: "image/jpg"))

        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await upload(request, from: formData.data)
        
        if response.statusCode == 200 || 200..<300 ~= response.statusCode {
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
        
        guard let url = URL(string: "\(supabaseUrl)/storage/v1/object/\(bucketName)/\(path)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.PUT.rawValue

        request.setValue(supabaseKey, forHTTPHeaderField: "authorization")
        
        let formData = FormData()
        formData.append(file: File(name: fileName, data: imageData, fileName: fileName, contentType: "image/jpg"))

        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await upload(request, from: formData.data)
        
        if response.statusCode == 200 || 200..<300 ~= response.statusCode {
            print("✅ Update Success")
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
        
        guard let url = URL(string: "\(supabaseUrl)/storage/v1/object/\(bucketName)/\(path)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.DELETE.rawValue

        request.setValue(supabaseKey, forHTTPHeaderField: "authorization")

        let parameters = ["prefixes": path]
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])

        let (data, response) = try await fetch(request)
        
        if response.statusCode == 200 || 200..<300 ~= response.statusCode {
            print("✅ Delete Success")
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
    
    private func fetch(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
      try await withCheckedThrowingContinuation { continuation in
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
          if let error = error {
            continuation.resume(throwing: error)
            return
          }

          guard
            let data = data,
            let httpResponse = response as? HTTPURLResponse
          else {
            continuation.resume(throwing: URLError(.badServerResponse))
            return
          }

          continuation.resume(returning: (data, httpResponse))
        }

        dataTask.resume()
      }
    }
    
    private func upload(
      _ request: URLRequest,
      from data: Data
    ) async throws -> (Data, HTTPURLResponse) {
      try await withCheckedThrowingContinuation { continuation in
        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
          if let error = error {
            continuation.resume(throwing: error)
            return
          }

          guard
            let data = data,
            let httpResponse = response as? HTTPURLResponse
          else {
            continuation.resume(throwing: URLError(.badServerResponse))
            return
          }
          continuation.resume(returning: (data, httpResponse))
        }
        task.resume()
      }
    }
}
