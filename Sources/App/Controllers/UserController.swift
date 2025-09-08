//
//  File.swift
//  
//
//  Created by 홍승아 on 5/15/24.
//

import Fluent
import Vapor

enum LoginType{
    case email, phoneNumber
}

struct UserController: RouteCollection{
    func boot(routes: Vapor.RoutesBuilder) throws {
        let user = routes.grouped("user")

        user.grouped("join").post(use: { try await self.create(req: $0) })
        user.grouped("update").post(use: { try await self.update(req: $0) })
    }
    
    func create(req: Request) async throws -> User{
        let userData = try req.content.decode(UserData.self)
        let user = User(id: UUID(), name: userData.name, description: userData.description, image: "", backgroundImage: "")
        let path = "profile"
        
        if let imageData = userData.image{
            user.image = try await SupabaseManager.shared.uploadImage(imageData: imageData, fileName: "\(user.id!.uuidString)_profile", path: path, req: req)
        }
        try await user.save(on: req.db)
        return user
    }
    
    func update(req: Request) async throws -> User{
        let userData = try req.content.decode(UserData.self)
        let newUser = User(id: UUID(userData.id), name: userData.name, description: userData.description, image: "", backgroundImage: "")
        
        if let user = try await User.find(UUID(userData.id), on: req.db){
            newUser.image = user.image
            newUser.backgroundImage = user.backgroundImage
            
            let path = "profile"
            
            let profileImageFileName = "\(newUser.id!.uuidString)_profile"
            if let imageData = userData.image{
                if user.image.count > 0 { // update
                    try await SupabaseManager.shared.updateImage(imageData: imageData, fileName: profileImageFileName, path: path, req: req)
                } else { // upload
                    newUser.image = try await SupabaseManager.shared.uploadImage(imageData: imageData, fileName: profileImageFileName, path: path, req: req)
                }
            } else { // delete
                if user.image.count > 0 {
                    try await SupabaseManager.shared.deleteImage(fileName: profileImageFileName, path: path, req: req)
                    newUser.image = ""
                }
            }
            
            let backgroundImageFileName = "\(newUser.id!.uuidString)_background"
            
            if let backgroundImageData = userData.backgroundImage{
                if user.backgroundImage.count > 0 { // update
                    try await SupabaseManager.shared.updateImage(imageData: backgroundImageData, fileName: backgroundImageFileName, path: path, req: req)
                } else { // upload
                    newUser.backgroundImage = try await SupabaseManager.shared.uploadImage(imageData: backgroundImageData, fileName: backgroundImageFileName, path: path, req: req)
                }
            } else { // delete
                if user.backgroundImage.count > 0{
                    try await SupabaseManager.shared.deleteImage(fileName: backgroundImageFileName, path: path, req: req)
                    newUser.backgroundImage = ""
                }
            }
               
            let _ = try await User.find(newUser.id, on: req.db).map{
                $0.name = newUser.name
                $0.description = newUser.description
                $0.image = newUser.image
                $0.backgroundImage = newUser.backgroundImage
                let _ = $0.update(on: req.db)
            }
            return newUser
        }
        
        return newUser
    }
}

// 업로드된 이미지의 데이터를 나타내는 구조체입니다.
struct ImageUploadData: Content, @unchecked Sendable {
    var filename: String
    var data: Data
}
