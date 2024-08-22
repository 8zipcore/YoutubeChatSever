import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import Mailgun

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "sainkr",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateChatRooms())
    app.migrations.add(CreateCategories())
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.routes.defaultMaxBodySize = "15mb"
    
    // 💌 Mailgun
//    app.mailgun.configuration = .init(apiKey: "1f867fcb14f55b93b98b2ea97485351e-0996409b-15a30e0c")
//    app.mailgun.defaultDomain = .test

    // register routes
    try routes(app)
}

extension MailgunDomain {
    static var test: MailgunDomain { .init("sandboxd62a243140064067b49523bfe6145f33.mailgun.org", .us) }
}
