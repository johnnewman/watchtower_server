//
//  CreateCamera.swift
//  
//
//  Created by John Newman on 3/21/21.
//

import Fluent

struct CreateCamera: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("cameras")
            .field("uuid", .uuid, .identifier(auto: false))
            .field("created_at", .date)
            .field("updated_at", .date)
            .field("name", .string, .required)
            .field("ip", .string)
            .unique(on: "name")
            .unique(on: "ip")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("cameras").delete()
    }
}
