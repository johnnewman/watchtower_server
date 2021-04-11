//
//  CameraExtensions.swift
//  
//
//  Created by John Newman on 4/11/21.
//

import XCTVapor
import Fluent
@testable import App

extension Camera {
    static func seed(id: UUID, name: String, ip: String, on db: Database) throws -> Camera {
        let camera = Camera(id: id, name: name, ip: ip)
        try camera.save(on: db).wait()
        return camera
    }
}
