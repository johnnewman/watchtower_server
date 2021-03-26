import Leaf
import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.databases.middleware.use(CameraMiddleware(), on: .sqlite)
    app.migrations.add(CreateCamera())
    app.views.use(.leaf)

    // register routes
    try routes(app)
}
