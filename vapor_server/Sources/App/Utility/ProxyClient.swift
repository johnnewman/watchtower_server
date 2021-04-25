//
//  ProxyClient.swift
//  
//
//  Created by John Newman on 4/24/21.
//

import Vapor

extension Client {
    func proxyGet(_ url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        return ProxyController.proxyClient.get(client: self, url: url, headers: headers, beforeSend: beforeSend)
    }
}

struct ClientStub {
    let host: String
    let status: HTTPStatus
    let headers: HTTPHeaders
    let body: Data?
}

/// The default `ProxyClient`, which simply sends the request to the client.
class ProxyClient {
    func get(client: Client, url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        return client.send(.GET, headers: headers, to: url, beforeSend: beforeSend)
    }
}

/// A subclass of `ProxyClient` that stubs responses from clients. Useful for unit testing.
class TestClient: ProxyClient {
    
    var stubs = [ClientStub]()
    
    /// Overridden to stub ClientResponse instances with any matching host in the `stubs` array.
    override func get(client: Client, url: URI, headers: HTTPHeaders = [:], beforeSend: (inout ClientRequest) throws -> () = { _ in }) -> EventLoopFuture<ClientResponse> {
        
        if let stub = stubs.first(where: { $0.host == url.host }) {
            return client.eventLoop.future(
                ClientResponse(
                    status: stub.status,
                    headers: stub.headers,
                    body: stub.body != nil ? ByteBuffer(data: stub.body!) : nil
                )
            )
        }
        return client.send(.GET, headers: headers, to: url, beforeSend: beforeSend)
    }
}
