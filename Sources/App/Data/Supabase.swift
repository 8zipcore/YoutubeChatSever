//
//  Supabase.swift
//
//
//  Created by 홍승아 on 1/2/25.
//

import Foundation
import Vapor

public struct File: Hashable, Equatable {
    public var name: String
    public var data: Data
    public var fileName: String?
    public var contentType: String?
    
    public init(name: String, data: Data, fileName: String?, contentType: String?) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.contentType = contentType
    }
}

public class FormData {
    var file: File
    var boundary: String
    
    public init(file: File) {
        self.boundary = "Boundary-\(UUID().uuidString)"
        self.file = file
    }
    
    public var body: ByteBuffer {
        var body = ByteBufferAllocator().buffer(capacity: 0)
        
        body.writeString("--\(boundary)\r\n")
        body.writeString("Content-Disposition: form-data; name=\"\(file.name)\"")
        if let filename = file.fileName?.replacingOccurrences(of: "\"", with: "_") {
            body.writeString("; filename=\"\(filename)\"")
        }
        
        body.writeString("\r\n")
        if let contentType = file.contentType {
            body.writeString("Content-Type: \(contentType)\r\n")
        }
        body.writeString("\r\n")
        var fileBuffer = ByteBuffer(data: file.data)  // 변경 가능한 ByteBuffer로 변환
        body.writeBuffer(&fileBuffer)  // inout을 사용하기 위해 &를 추가
        body.writeString("\r\n")
        
        body.writeString("--\(boundary)--\r\n")
        
        return body
    }
}
