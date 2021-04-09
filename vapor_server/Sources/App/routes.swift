import Leaf
import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    app.get { req in
        return "Watchtower Server"
    }
    
    try app.register(collection: CameraController())
}
