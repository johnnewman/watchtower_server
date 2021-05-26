import Leaf
import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    app.get { req in
        return "Watchtower Server"
    }
    
    try app.register(collection: CameraController())
    try app.register(collection: ProxyController())
    try app.register(collection: EventController())
    
    if app.environment == .testing {
        ProxyController.proxyClient = TestClient()
    }
}
