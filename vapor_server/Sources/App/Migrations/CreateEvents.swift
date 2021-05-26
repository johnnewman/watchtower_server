//
//  File.swift
//  
//
//  Created by John Newman on 5/25/21.
//

import Fluent

struct CreateEvents: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("events")
            .id()
            .field("created_at", .date)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("events").delete()
    }
}
