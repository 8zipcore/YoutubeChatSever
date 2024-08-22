//
//  File.swift
//  
//
//  Created by 홍승아 on 5/14/24.
//

import Fluent
import Vapor

enum LoginResponse: Int, Codable{
    case invalidAccount
    case invalidPassword
    case success
}

struct LoginController: RouteCollection{
    func boot(routes: Vapor.RoutesBuilder) throws {
        // routes.grouped("login").post(use: { try await self.login(req: $0).rawValue })
    }
    
    /*
    func login(req: Request) async throws -> LoginResponse{
        let data = try req.content.decode(User.self)
        
        guard let user = try await User.query(on: req.db).all().filter({$0.userID == data.userID}).first else {
            return LoginResponse.invalidAccount
        }
        
        if user.userPassword == data.userPassword {
            return LoginResponse.success
        } else {
            return LoginResponse.invalidPassword
        }
    }
     */
}
