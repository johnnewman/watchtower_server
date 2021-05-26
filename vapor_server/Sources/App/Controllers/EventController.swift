//
//  File.swift
//  
//
//  Created by John Newman on 5/24/21.
//

import Fluent
import Vapor
import NIO

struct EventController: RouteCollection {
        
    static var proxyClient = ProxyClient()
    
    private var storageDir: String {
        Environment.process.STORAGE_DIR!
    }
    
    func boot(routes: RoutesBuilder) throws {
        let events = routes.grouped("events")
        events.webSocket("upload") { req, sock in
            
//            guard let address = req.ipv4Address else {
//                print("Error finding IP address.")
//                let _ = sock.close(code: .policyViolation)
//                return
//            }
            let address = "127.0.0.1"
            
            let fileHandleFuture = Camera.query(on: req.db)
                .filter(\.$ip == address)
                .first()
                .flatMap { camera -> EventLoopFuture<Camera?> in
                    
                    guard let camera = camera else {
                        print("No camera found.")
                        return req.eventLoop.future(nil)
                    }
                    
                    return Event.query(on: req.db)
                        .sort(\.$createdAt)
                        .first()
                        .flatMap { latestEvent in
                            if let latestEvent = latestEvent {
                                print("Existing event found.")
                                camera.event = latestEvent
                            } else {
                                print("Creating new event.")
                                camera.event = Event()
                            }
                            return camera.save(on: req.db).map { camera }
                        }
                }
                .map { camera -> NIOFileHandle? in
                    guard let camera = camera else {
                        return nil
                    }
                    return try? NIOFileHandle(path: "\(storageDir)/\(camera.event!.id!)/\(camera.name)/1234.bin", mode: .write, flags: .allowFileCreation())
                }
            
            sock.onBinary { sock, bytes in
                
                fileHandleFuture.whenSuccess { handle in
                    guard let handle = handle else {
                        print("Error opening file handle.")
                        let _ = sock.close(code: .unexpectedServerError)
                        return
                    }
                    
                    let _ = req.application.fileio.readFileSize(
                        fileHandle: handle,
                        eventLoop: req.eventLoop
                    ).map { size in
                        req.application.fileio.write(
                            fileHandle: handle,
                            toOffset: size,
                            buffer: bytes,
                            eventLoop: req.eventLoop
                        )
                        .whenComplete { _ in
                            print("Received chunk.")
                            sock.send("received")
                        }
                    }
                }
            }
            
            sock.onClose.whenComplete { result in
                fileHandleFuture.whenSuccess { handle in
                    try? handle?.close()
                    print("Complete!")
                }
            }
        }
    }
}



