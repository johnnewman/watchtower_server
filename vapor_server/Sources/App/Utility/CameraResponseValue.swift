//
//  CameraResponseValue.swift
//  
//
//  Created by John Newman on 4/24/21.
//

import Vapor

/// Stores the value for each key/value pair in the response from a proxy request to a Camera. This is used to
/// conform the various data types that may be returned to `Content`.
enum CameraResponseValue: Codable, Content, Equatable {
    
    case bool(_: Bool)
    case string(_: String)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .bool(try container.decode(Bool.self))
        } catch {
            self = .string(try container.decode(String.self))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .bool(boolValue):
            try container.encode(boolValue)
        case let .string(stringValue):
            try container.encode(stringValue)
        }
    }
}
