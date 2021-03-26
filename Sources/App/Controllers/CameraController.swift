//
//  CameraController.swift
//  
//
//  Created by John Newman on 3/21/21.
//

import Fluent
import Vapor

struct CameraController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cameras = routes.grouped("cameras")
        cameras.get(use: index)
        cameras.post(use: upsert)
        cameras.group(":id") { camera in
            camera.delete(use: delete)
            camera.get(use: get)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[Camera]> {
        return Camera.query(on: req.db).all()
    }
    
    func upsert(req: Request) throws -> EventLoopFuture<Camera> {
        try Camera.validate(content: req)
        let cameraToSave = try req.content.decode(Camera.self)
        cameraToSave.ip = try address(fromRequest: req)
        
        guard let uuid = cameraToSave.id else {
            throw Abort(.unprocessableEntity)
        }
        
        // Search for the camera in the database or create a new one.
        return Camera.query(on: req.db)
            .filter(\.$id == uuid)
            .first()
            .flatMapThrowing { queriedCam -> Camera in
                var newCamera: Camera
                if let queriedCam = queriedCam {
                    
                    if cameraToSave == queriedCam {
                        // If nothing changed, no need to update.
                        throw Abort(.notModified)
                    }
                    
                    newCamera = queriedCam
                    newCamera.name = cameraToSave.name
                    newCamera.ip = cameraToSave.ip
                } else {
                    newCamera = cameraToSave
                }
                return newCamera
            }.flatMap { cam in
                return cam.save(on: req.db).map { cam }
            }
    }
    
    func get(req: Request) throws -> EventLoopFuture<Camera> {
        return Camera.find(req.parameters.get("id"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
    
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return try get(req: req)
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    /// Extracts the ipv4 address from the request.
    /// - Parameter req: The request to extract the ip address from.
    /// - Throws: An abort error if there is no valid ip address.
    /// - Returns: The ipv4 address string from the request.
    func address(fromRequest req: Request) throws -> String {
        guard let address = req.remoteAddress,
              address.protocol == .inet,
              let ipAddress = address.ipAddress else {
            throw Abort(.unprocessableEntity)
        }
        return ipAddress
    }
}
