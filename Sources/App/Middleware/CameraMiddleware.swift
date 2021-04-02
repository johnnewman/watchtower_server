//
//  CameraMiddleware.swift
//  
//
//  Created by John Newman on 3/21/21.
//

import Fluent
import Vapor
import Socket

struct CameraMiddleware: ModelMiddleware {
    
    typealias Model = Camera
    
    fileprivate static let logger = Logger(label: "camera.middleware")
    
    let outputFile = "vapor_test_template.txt"
    
    /// The global application. Used to access the event loop.
    var app: Application
    
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void> {
        
        guard let camera = model as? Camera else {
            return next.handle(event, model, on: db)
        }
        CameraMiddleware.logger.info("Did \(event) \"\(camera.name)\".")
        
        switch event {
        case .delete(_), .create, .update:
            return next.handle(event, model, on: db).map { generateTemplate(from: db) }
        default:
            return next.handle(event, model, on: db)
        }
    }
    
    /// Generates a new nginx template file and, once complete, transmits a message over a socket to notify
    /// the server that a new template is ready.
    /// - Parameter db: The database to use for fetching all cameras.
    func generateTemplate(from db: Database) {
        let outputFuture = app.eventLoopGroup.future()
            .renderTemplate(from: db, using: app.leaf.renderer)
            .output(to: outputFile, app: app)
        
        // Dispatch on a background queue to output the file and message the socket.
        DispatchQueue.global(qos: .background).async {
            do {
                let _ = try outputFuture.wait()
                try Socket.write("1234", to: "wt.sock")
            } catch ResponseError.empty(let message) {
                CameraMiddleware.logger.error("Failed to receive a response after transmitting \"\(message)\".")
            } catch ResponseError.failure(let message) {
                CameraMiddleware.logger.error("Received a failure message after transmitting \"\(message)\".")
            } catch {
                CameraMiddleware.logger.error("Failed to generate nginx template: \(error)")
            }
        }
    }
}
