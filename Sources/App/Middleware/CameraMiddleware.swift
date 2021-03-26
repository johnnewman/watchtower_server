//
//  CameraMiddleware.swift
//  
//
//  Created by John Newman on 3/21/21.
//

import Fluent
import Vapor

struct CameraMiddleware: ModelMiddleware {
    typealias Model = Camera
    
    static let logger = Logger(label: "camera.middleware")
    
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void> {
        
        guard let camera = model as? Camera else {
            return next.handle(event, model, on: db)
        }
        
        switch event {
        case .delete(_), .create, .update:
            return next.handle(event, model, on: db).map {
                CameraMiddleware.logger.info("Did \(event) \"\(camera.name)\".")
                Camera.query(on: db).all().whenSuccess {
                    generateNginxTemplate($0)
                }
            }
        default:
            return next.handle(event, model, on: db)
        }
    }
}
