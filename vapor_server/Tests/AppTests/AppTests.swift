@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    
    let sut = Application(.testing)
    
    override func setUpWithError() throws {
        try configure(sut)
        try sut.autoRevert().wait()
        try sut.autoMigrate().wait()
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        sut.shutdown()
        try super.tearDownWithError()
    }
    
    func testUnknownEndpoint() throws {
        // Endpoint must be /api/cameras
        try sut.test(.GET, "/cameras") {
            XCTAssertEqual($0.status, .notFound)
        }
    }
    
    // MARK: - /cameras - Fetching all cameras
    
    func testCamerasIndexGivenNone() throws {
        try sut.test(.GET, "/api/cameras") {
            XCTAssertEqual($0.status, .ok)
            XCTAssertEqual($0.body.string, "[]")
        }
    }
    
    func testCamerasIndexGivenOne() throws {
        let cam = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        try sut.test(.GET, "/api/cameras") {
            XCTAssertEqual($0.status, .ok)
            let cameras = try $0.content.decode([Camera].self)
            XCTAssert(cameras.count == 1)
            XCTAssertEqual(cameras.first!, cam)
        }
    }
    
    func testCamerasIndexGivenMultiple() throws {
        let cam1 = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        let cam2 = try Camera.seed(
            id: UUID(),
            name: "Camera2",
            ip: "192.168.1.101",
            on: sut.db
        )
        try sut.test(.GET, "/api/cameras") {
            XCTAssertEqual($0.status, .ok)
            let cameras = try $0.content.decode([Camera].self)
            XCTAssert(cameras.count == 2)
            XCTAssertEqual(cameras.first { $0.id == cam1.id }, cam1)
            XCTAssertEqual(cameras.first { $0.id == cam2.id }, cam2)
        }
    }
    
    // MARK: - /cameras/:id - Individual cameras
    
    func testGetCamera() throws {
        let cam = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        try sut.test(.GET, "/api/cameras/\(cam.id!.uuidString)") {
            XCTAssertEqual($0.status, .ok)
            let fetchedCam = try $0.content.decode(Camera.self)
            XCTAssertEqual(fetchedCam, cam)
        }
    }
    
    func testGetUnknownCamera() throws {
        try sut.test(.GET, "/api/cameras/\(UUID().uuidString)") {
            XCTAssertEqual($0.status, .notFound)
        }
    }
    
    func testDeleteCamera() throws {
        let cam = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        try sut.test(.DELETE, "/api/cameras/\(cam.id!.uuidString)") { deleteResponse in
            XCTAssertEqual(deleteResponse.status, .ok)
            
            try sut.test(.GET, "/api/cameras/\(cam.id!.uuidString)") { getResponse in
                XCTAssertEqual(getResponse.status, .notFound)
            }
        }
    }
    
    func testDeleteUnknownCamera() throws {
        try sut.test(.DELETE, "/api/cameras/\(UUID().uuidString)") {
            XCTAssertEqual($0.status, .notFound)
        }
    }
    
    // MARK: - Creating cameras
    
    func testCreateCamera() throws {
        let uuid = UUID().uuidString
        let ip = "192.168.1.100"
        try sut.upsertCamera(name: "TestCamera", id: uuid, address: ip) {
            XCTAssertEqual($0.status, .ok)
            let createdCamera = try $0.content.decode(Camera.self)
            XCTAssertEqual(createdCamera.name, "TestCamera")
            XCTAssertEqual(createdCamera.id!.uuidString, uuid)
            XCTAssertEqual(createdCamera.ip, ip)
            
            try self.sut.test(.GET, "/api/cameras/\(uuid)") { getResponse in
                XCTAssertEqual(getResponse.status, .ok)
                let fetchedCamera = try getResponse.content.decode(Camera.self)
                XCTAssertEqual(fetchedCamera, createdCamera)
            }
        }
    }
    
    func testCreateCameraWithBadId() throws {
        try sut.upsertCamera(name: "Camera", id: "asdf", address: "192.168.1.100") {
            XCTAssertEqual($0.status, .badRequest)
        }
    }
    
    func testCreateCameraWithBadName() throws {
        let name = "Test\n\nCamera "
        try sut.upsertCamera(name: name, id: UUID().uuidString, address: "192.168.1.100") {
            XCTAssertEqual($0.status, .badRequest)
        }
    }
    
    func testCreateCameraWithBadIP() throws {
        let ip = "192.168.1.alpha"
        try sut.upsertCamera(name: "TestCamera", id: UUID().uuidString, address: ip) {
            XCTAssertEqual($0.status, .unprocessableEntity)
        }
    }
    
    func testCreateCameraWithDuplicateIp() throws {
        let cam = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        try sut.upsertCamera(name: "TestCamera", id: UUID().uuidString, address: cam.ip!) {
            XCTAssertEqual($0.status, .internalServerError)
        }
    }
    
    func testCreateCameraWithDuplicateName() throws {
        let cam = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        try sut.upsertCamera(name: cam.name, id: UUID().uuidString, address: "192.168.1.255") {
            XCTAssertEqual($0.status, .internalServerError)
        }
    }
    
    // MARK: - Updating cameras
    
    func testUpdateCamera() throws {
        let cam = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        let newName = "NewName"
        let newAddress = "192.168.1.255"
        try sut.upsertCamera(name: newName, id: cam.id!.uuidString, address: newAddress) {
            XCTAssertEqual($0.status, .ok)
            let updatedCamera = try $0.content.decode(Camera.self)
            XCTAssertEqual(updatedCamera.name, newName)
            XCTAssertEqual(updatedCamera.ip, newAddress)
        }
    }
    
    func testUpdateCameraNoChanges() throws {
        let cam = try Camera.seed(
            id: UUID(),
            name: "Camera1",
            ip: "192.168.1.100",
            on: sut.db
        )
        try sut.upsertCamera(name: cam.name, id: cam.id!.uuidString, address: cam.ip!) {
            XCTAssertEqual($0.status, .notModified)
        }
    }
}
