import Leaf
import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) throws {
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
    app.databases.middleware.use(CameraMiddleware(app: app), on: .sqlite)
    app.migrations.add(CreateCamera())
    if app.environment != .testing {
        let _ = app.autoMigrate()
    }
    app.views.use(.leaf)

    // register routes
    try routes(app)
}
