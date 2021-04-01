//
//  CameraMiddleware.swift
//  
//
//  Created by John Newman on 3/21/21.
//

import Fluent
import NIO
import Vapor

struct CameraMiddleware: ModelMiddleware {
    typealias Model = Camera
    
    var app: Application
    
    let leafTemplateName = "nginx"
    let leafTemplateKey = "cameras"
    let nginxTemplateOutputName = "vapor_test_template.txt"
    
    static let logger = Logger(label: "camera.middleware")
    
    func handle(_ event: ModelEvent, _ model: AnyModel, on db: Database, chainingTo next: AnyModelResponder) -> EventLoopFuture<Void> {
        
        guard let camera = model as? Camera else {
            return next.handle(event, model, on: db)
        }
        
        switch event {
        case .delete(_), .create, .update:
            return next.handle(event, model, on: db).map {
                CameraMiddleware.logger.info("Did \(event) \"\(camera.name)\".")
                let outputFuture = Camera.query(on: db).all().flatMap { cameras -> EventLoopFuture<()> in
                    app.leaf.renderer.render(leafTemplateName, [leafTemplateKey: cameras]).flatMap { view -> EventLoopFuture<()> in
                        guard let handle = try? NIOFileHandle(path: nginxTemplateOutputName, mode: .write, flags: .allowFileCreation()) else {
                            return app.eventLoopGroup.future()
                        }
                        let fileFuture = app.fileio.write(fileHandle: handle, buffer: view.data, eventLoop: app.eventLoopGroup.next())
                        fileFuture.whenComplete { _ in
                            try? handle.close()
                        }
                        return fileFuture
                    }
                }
                DispatchQueue.global(qos: .background).async {
                    try? outputFuture.wait()
                }
            }
        default:
            return next.handle(event, model, on: db)
        }
    }
}
