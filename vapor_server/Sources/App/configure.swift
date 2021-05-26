import Leaf
import Fluent
import FluentSQLiteDriver
import Vapor
import NIOSSL

enum AppError: Error {
    case missingEnvVariable(_: String)
}

public func configure(_ app: Application) throws {
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        guard let storageDir = Environment.process.STORAGE_DIR else {
            throw AppError.missingEnvVariable("STORAGE_DIR")
        }
        app.databases.use(.sqlite(.file("\(storageDir)/db.sqlite")), as: .sqlite)
    }
    app.databases.middleware.use(CameraMiddleware(app: app), on: .sqlite)
    app.migrations.add(CreateEvents())
    app.migrations.add(CreateCamera())
    if app.environment != .testing {
        let _ = app.autoMigrate()
    }
    app.views.use(.leaf)
    
    try routes(app)
    
    if app.environment != .testing {
        try loadCerts(app)
    }
}

/// Loads TLSConfiguration necessary for validating with upstream cameras.
private func loadCerts(_ app: Application) throws {
    guard let certDir = Environment.process.CERT_DIR,
          let upstreamCA = Environment.process.UPSTREAM_CA else {
        throw AppError.missingEnvVariable("CERT_DIR or UPSTREAM_CA")
    }
    guard let clientCertName = Environment.process.CLIENT_CERT else {
        throw AppError.missingEnvVariable("CLIENT_CERT")
    }
    guard let clientKeyName = Environment.process.CLIENT_KEY else {
        throw AppError.missingEnvVariable("CLIENT_KEY")
    }
    guard let clientCert = try NIOSSLCertificate.fromPEMFile("\(certDir)/\(clientCertName)").first else {
        throw NIOSSLError.failedToLoadCertificate
    }
    
    app.http.client.configuration.tlsConfiguration = .forClient(
        certificateVerification: .noHostnameVerification,
        trustRoots: .file("\(certDir)/\(upstreamCA)"),
        certificateChain: [.certificate(clientCert)],
        privateKey: .file("\(certDir)/\(clientKeyName)")
    )
}
