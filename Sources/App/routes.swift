import Leaf
import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    app.get { req in
        return "Watchtower Server"
    }
    
    app.get("output_template") { req -> EventLoopFuture<View> in
        return Camera.query(on: req.db).all().flatMap { (cameras) in
            return app.leaf.renderer.render("nginx", ["cameras": cameras]).flatMap { (view) in
                return req.fileio.writeFile(view.data, at: "vapor_test_template.txt").map { _ in
                    return view
                }
            }
        }
    }
    
    try app.register(collection: CameraController())
}
