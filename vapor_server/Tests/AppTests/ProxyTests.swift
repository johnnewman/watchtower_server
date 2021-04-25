//
//  ProxyTests.swift
//  
//
//  Created by John Newman on 4/18/21.
//

@testable import App
import XCTVapor


struct CameraStub {
    var camera: Camera
    var stub: ClientStub
}

final class ProxyTests: XCTestCase {
    
    let sut = Application(.testing)
    var successfulStub: CameraStub!
    var encodingFailureStub: CameraStub!
    
    override func setUpWithError() throws {
        try configure(sut)
        try sut.autoRevert().wait()
        try sut.autoMigrate().wait()
        
        successfulStub = CameraStub(
            camera: Camera(
                id: UUID(),
                name: "Kitchen",
                ip: "192.168.1.100"
            ),
            stub: ClientStub(
                host: "192.168.1.100",
                status: .ok,
                headers: HTTPHeaders([("content-type", "application/json")]),
                body: try JSONEncoder().encode(["monitoring": true])
            )
        )
        
        encodingFailureStub = CameraStub(
            camera: Camera(
                id: UUID(),
                name: "LivingRoom",
                ip: "192.168.1.99"
            ),
            stub: ClientStub(
                host: "192.168.1.99",
                status: .badGateway,
                headers: HTTPHeaders([("content-type", "application/json")]),
                body: try JSONEncoder().encode("") // Error
            )
        )
        
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        sut.shutdown()
        (ProxyController.proxyClient as? TestClient)?.stubs.removeAll()
        try super.tearDownWithError()
    }
    
    func testUnknownEndpoint() throws {
        // Endpoint must be /api/status
        try sut.test(.GET, "/status") {
            XCTAssertEqual($0.status, .notFound)
        }
    }
    
    func testProxyStatusGivenOneClient() throws {
        try successfulStub.camera.save(on: sut.db).wait()
        (ProxyController.proxyClient as? TestClient)?.stubs.append(successfulStub.stub)
        
        try sut.test(.GET, "/api/status") {
            let expectedData =  [successfulStub.camera.name:["monitoring": CameraResponseValue.bool(true)]]
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual(try $0.content.decode([String: [String: CameraResponseValue]].self), expectedData)
        }
    }
    
    func testProxyStatusGivenTwoClients() throws {
        try successfulStub.camera.save(on: sut.db).wait()
        try encodingFailureStub.camera.save(on: sut.db).wait()
        (ProxyController.proxyClient as? TestClient)?.stubs.append(contentsOf: [successfulStub.stub, encodingFailureStub.stub])
        
        try sut.test(.GET, "/api/status") {
            let expectedData: [String: [String: CameraResponseValue]] = [
                successfulStub.camera.name: ["monitoring": .bool(true)],
                encodingFailureStub.camera.name: ["error": .string("failed to decode response")]
            ]
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual(try $0.content.decode([String: [String: CameraResponseValue]].self) , expectedData)
        }
    }
    
    func testProxyStart() throws {
        try successfulStub.camera.save(on: sut.db).wait()
        (ProxyController.proxyClient as? TestClient)?.stubs.append(successfulStub.stub)
        
        try sut.test(.GET, "/api/start") {
            let expectedData =  [successfulStub.camera.name:["monitoring": CameraResponseValue.bool(true)]]
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual(try $0.content.decode([String: [String: CameraResponseValue]].self), expectedData)
        }
    }
    
    func testProxyStop() throws {
        try successfulStub.camera.save(on: sut.db).wait()
        (ProxyController.proxyClient as? TestClient)?.stubs.append(successfulStub.stub)
        
        try sut.test(.GET, "/api/stop") {
            let expectedData =  [successfulStub.camera.name:["monitoring": CameraResponseValue.bool(true)]]
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual(try $0.content.decode([String: [String: CameraResponseValue]].self), expectedData)
        }
    }
}
