@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    
    let sut = Application(.testing)
    
    override func setUpWithError() throws {
        defer { sut.shutdown() }
        try configure(sut)
        super.setUp()
    }
    
    
    
    func testHelloWorld() throws {
//        let app = Application(.testing)
//        defer { app.shutdown() }
//        try configure(app)

//        try app.test(.GET, "hello", afterResponse: { res in
//            XCTAssertEqual(res.status, .ok)
//            XCTAssertEqual(res.body.string, "Hello, world!")
//        })
    }
    
    func testGetCamerasGivenNone() throws {
        try sut.test(.GET, "cameras", afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "[]")
        })
    }
}
