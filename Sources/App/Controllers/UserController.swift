//
//  File.swift
//  
//
//  Created by 홍승아 on 5/15/24.
//

import Fluent
import Vapor
import Mailgun

enum LoginType{
    case email, phoneNumber
}

struct UserController: RouteCollection{
    func boot(routes: Vapor.RoutesBuilder) throws {
        let user = routes.grouped("user")

        user.grouped("join").post(use: { try await self.create(req: $0) })
        user.grouped("update").post(use: { try await self.update(req: $0) })
        
//        join.group(":email") { joinEmail in
//            joinEmail.get(use: { try await self.checkIDVaildation(req: $0) } )
//        }
//        
//        let emailVerification = join.grouped("emailVerification")
//        
//        emailVerification.group(":id"){ verification in
//            verification.get(use: { try await self.sendEmailVerificationCode(req: $0) })
//        }
//        
//        emailVerification.post(use: { try await self.verifyEmailVerificationCode(req: $0).rawValue })
    }
    
    func create(req: Request) async throws -> User{
        let user = try req.content.decode(User.self)
        try await user.save(on: req.db)
        return user
    }
    
    func update(req: Request) async throws -> User{
        let user = try req.content.decode(User.self)
        let _ = try await User.find(user.id, on: req.db).map{
            $0.name = user.name
            $0.description = user.description
            $0.image = user.image
            $0.backgroundImage = user.image
            let _ = $0.update(on: req.db)
        }
        return user
    }
}

// 업로드된 이미지의 데이터를 나타내는 구조체입니다.
struct ImageUploadData: Content, @unchecked Sendable {
    var filename: String
    var data: Data
}


/*

// email 가입
extension JoinController{
    // email 유효성 체크
    func checkIDVaildation(req: Request) async throws -> IDValidationResponseData{
        guard let email = req.parameters.get("email") else { return IDValidationResponseData(code: .fail, id: nil)}
       
        let users = try await User.query(on: req.db).all()
        
        if let _ = users.filter({ $0.email == email }).first{
            return IDValidationResponseData(code: .fail, id: nil, text: "계정 중복 알림/\(email) 계정은 사용하실 수 없습니다./확인")
        } else {
            let joinUser = JoinUser(email: email,
                                    phoneNumber: "",
                                    verificationCode: "")
            try await joinUser.create(on: req.db)
            return IDValidationResponseData(code: .success, id: joinUser.id, text: email)
        }
    }

    // email 인증코드 전송
    func sendEmailVerificationCode(req: Request) async throws -> HTTPStatus {
        guard let joinUser = try await JoinUser.find(req.parameters.get("id"), on: req.db) else {
            return .notFound
        }

        let verificationCodeToString = String(VerificationCodeGenerator().generate())
        
        let message = MailgunMessage(
            from: "test@test",
            to: joinUser.email,
            subject: "인증번호",
            text: verificationCodeToString
        )
        
        let result = try await req.mailgun().send(message).get()
        
        if result.status == .ok {
            let _ = try await JoinUser.find(req.parameters.get("id"), on: req.db)
                .flatMap{
                    $0.verificationCode = verificationCodeToString
                    return $0.update(on: req.db)
                }
            
            return .ok
        }
        
        return .badRequest
    }
    
    // email 인증 번호 체크
    func verifyEmailVerificationCode(req: Request) async throws -> EmailVerificationResponseCode{
        let data = try req.content.decode(EmailVerificationRequestData.self)
        
        guard let joinUser = try await JoinUser.find(data.id, on: req.db) else {
            return .fail
        }
        
        if data.verificationCode.elementsEqual(joinUser.verificationCode){
            return .success
        }
        
        return .fail
    }
}

*/
