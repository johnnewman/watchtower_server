//
//  AppExtensions.swift
//  
//
//  Created by John Newman on 4/11/21.
//

import XCTVapor
@testable import App

extension Application {
    func upsertCamera(name: String, id: String, address: String, afterResponse: @escaping (XCTHTTPResponse) throws -> ()) throws {
        let testData = [
            "name": name,
            "id": id
        ]
        try test(.POST, "/api/cameras", headers: ["X-Real-IP":address], beforeRequest: {
            try $0.content.encode(testData)
        }, afterResponse: afterResponse)
    }
}
