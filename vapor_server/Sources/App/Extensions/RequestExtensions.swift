//
//  RequestExtensions.swift
//  
//
//  Created by John Newman on 4/11/21.
//

import Vapor
import NIO

extension Request {
        
    /// Extracts the ipv4 address from the request headers.
    var ipv4Address: String? {
        guard let headerIP = headers["X-Real-IP"].first,
              let address = try? SocketAddress(ipAddress: headerIP, port: 8080),
              address.protocol == .inet,
              let ipAddress = address.ipAddress else {
            
            logger.warning("Unable to extract IP address from request.")
            return nil
        }
        return ipAddress
    }
}
