//
//  FutureExtensions.swift
//  
//
//  Created by John Newman on 4/2/21.
//

import Fluent
import LeafKit
import NIO
import Vapor

extension EventLoopFuture {
    
    /// Creates a future to fetch all cameras from the database and renders them in the nginx template.
    /// - Parameters:
    ///   - db: The database to use to fetch the cameras.
    ///   - renderer: The leaf renderer to render the template.
    /// - Returns: A future with the rendered view.
    func renderTemplate(from db: Database, using renderer: LeafRenderer) -> EventLoopFuture<View> {
        flatMap { _ in
            Camera.query(on: db).all().flatMap { cameras in
                renderer.render("nginx", ["cameras": cameras])
            }
        }
    }
}

extension EventLoopFuture where Value == [Camera] {
    func flatProxyGet(_ endpoint: PathComponent, on req: Request) -> EventLoopFuture<[CameraData<ClientResponse>]> {
        flatMapEach(on: eventLoop) { camera -> EventLoopFuture<CameraData<ClientResponse>> in
            guard let ip = camera.ip else {
                return req.eventLoop.future(CameraData<ClientResponse>(camera, error: ProxyError.badCameraData))
            }
            return req.client.get("https://\(ip)/\(endpoint)").map { clientResponse in
                CameraData<ClientResponse>(camera, object: clientResponse)
            }
        }
    }
}

extension EventLoopFuture where Value == [CameraData<ClientResponse>] {
    func reduceIntoDict() -> EventLoopFuture<[String: String]> {
        map { allCameraData -> [String: String] in
            allCameraData.reduce(into: [String: String]()) { result, next in
                guard let response = next.object else {
                    result[next.camera.name] = (next.error ?? ProxyError.badCameraData).localizedDescription
                    return
                }
                guard var body = response.body else {
                    result[next.camera.name] = "Empty response body"
                    return
                }
                result[next.camera.name] = body.readString(length: body.readableBytes)
            }
        }
    }
}

extension EventLoopFuture where Value == View {
    
    /// Creates a future that outputs the view's data to the supplied file path.
    /// - Parameters:
    ///   - to: The path to output the view data.
    ///   - app: The application. Used to access the event loop.
    /// - Returns: A future with the view.
    func output(to: String, app: Application) -> EventLoopFuture<View> {
        flatMap { view in
            guard let handle = try? NIOFileHandle(path: to, mode: .write, flags: .allowFileCreation()) else {
                return app.eventLoopGroup.future(
                    error: IOError(
                        errnoCode: 0,
                        reason: "Failed to create file handle for \"\(to)\"."
                    )
                )
            }
                        
            // Write the rendered template to the file.
            let fileFuture = app.fileio.write(
                fileHandle: handle,
                buffer: view.data,
                eventLoop: app.eventLoopGroup.next()
            )
            fileFuture.whenComplete { _ in
                try? handle.close()
            }
            return fileFuture.map { view }
        }
    }
}
