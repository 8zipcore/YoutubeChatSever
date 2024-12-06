import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Mailgun

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    /*
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "sainkr",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)
    */
    
    app.databases.use(try .postgres(url: Environment.get("DATABASE_URL") ?? ""), as: .psql)
    print("✅ DATABASE_URL : \(Environment.get("DATABASE_URL") ?? "nil")")
    
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateChatRooms())
    app.migrations.add(CreateCategories())
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.routes.defaultMaxBodySize = "15mb"
    
    // register routes
    try routes(app)
    
    try await app.autoMigrate().get()
}
