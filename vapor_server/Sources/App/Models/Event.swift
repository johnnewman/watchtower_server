//
//  File.swift
//  
//
//  Created by John Newman on 5/25/21.
//

import Fluent
import Vapor

final class Event: Model, Content {
    
    static let schema = "events"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Children(for: \.$event)
    var cameras: [Camera]
    
}
