//
//  ProxyController.swift
//  
//
//  Created by John Newman on 4/14/21.
//

import Fluent
import Vapor

struct CameraData<T> {
    var camera: Camera
    var object: T?
    var error: Error?
    
    init(_ camera: Camera, error: Error) {
        self.camera = camera
        self.error = error
    }
    
    init(_ camera: Camera, object: T) {
        self.camera = camera
        self.object = object
    }
}

enum ProxyError: Error {
    case badCameraData
}

struct ProxyController: RouteCollection {
    
    static var proxyClient = ProxyClient()
    
    func boot(routes: RoutesBuilder) throws {
        let simpleProxyEndpoints: [PathComponent] = ["status", "start", "stop"]
        simpleProxyEndpoints.forEach { endpoint in
            routes.get(endpoint) { req in
                Camera.query(on: req.db)
                    .all()
                    .flatProxyGet(endpoint, on: req)
                    .reduceIntoDict()
            }
        }
    }
}
