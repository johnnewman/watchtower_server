//
//  SocketExtensions.swift
//  
//
//  Created by John Newman on 4/2/21.
//

import Foundation
import Socket
import Vapor

enum ResponseError: Error {
    case empty(message: String)
    case failure(message: String)
}

extension Socket {
    
    fileprivate static let logger = Logger(label: "socket")
    
    /// Transmits the provided message over a unix socket.
    /// - Parameters:
    ///   - message: The message to transmit.
    ///   - sockPath: The unix socket path.
    /// - Throws: Any error that arose while transmitting.
    class func write(_ message: String, to sockPath: String) throws {
        let sock = try Socket.create(family: .unix, type: .stream, proto: .unix)
        try sock.connect(to: sockPath)
        try sock.write(from: message)
        guard let response = try sock.readString() else {
            throw ResponseError.empty(message: message)
        }
        if response != "ok" {
            throw ResponseError.failure(message: message)
        }
        Socket.logger.debug("Successfully transmitted message \"\(message)\" to \(sockPath).")
    }
}
