//
//  Camera.swift
//  
//
//  Created by John Newman on 3/21/21.
//

import Fluent
import Vapor

final class Camera: Model, Content {
    
    static let schema = "cameras"
    
    @ID(custom: "uuid", generatedBy: .user)
    var id: UUID?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Field(key: "name")
    var name: String
    
    @Field(key: "ip")
    var ip: String?

    init() { }

    init(id: UUID? = nil, name: String, ip: String) {
        self.id = id
        self.name = name
        self.ip = ip
    }
}

extension Camera: Equatable {
    static func == (lhs: Camera, rhs: Camera) -> Bool {
        return lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.ip == rhs.ip
    }
}

extension Camera: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty && .alphanumeric)
    }
}
