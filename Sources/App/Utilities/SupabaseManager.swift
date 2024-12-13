//
//  SupabaseManager.swift
//
//
//  Created by 홍승아 on 12/11/24.
//

import Foundation
import Vapor
import Supabase

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
    }
    
    func updateImage(imageData: Data, fileName: String, path: String, req: Request) async throws{
        let supabase = SupabaseStorageClient(url: "\(supabaseUrl)/storage/v1", headers: [
            "authorization": supabaseKey,
        ])
        
        let path = "public/\(path)/\(fileName).jpg"
        let file = File(name: fileName, data: imageData, fileName: fileName, contentType: "image/jpg")
        
        let _ = try await supabase.from(id: bucketName)
            .update(path: path, file: file, fileOptions: nil)
        print(path)
        print("✅ update")
    }
    
    func deleteImage(fileName: String, path: String, req: Request) async throws {
        let supabase = SupabaseStorageClient(url: "\(supabaseUrl)/storage/v1", headers: [
            "authorization": supabaseKey,
        ])
        
        let path = "public/\(path)/\(fileName).jpg"
        
        let _ = try await supabase.from(id: bucketName).remove(paths: [path])
        print(path)
        print("✅ delete")
    }
}
