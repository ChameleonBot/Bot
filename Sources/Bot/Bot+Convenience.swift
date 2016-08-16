import class Vapor.Droplet

/*
 
 I write messy boilerplate so you don't have to ;)
 
 */

public extension SlackBot {
    public convenience init<
        Auth: SlackAuthenticator & DependencyBuildable,
        Data: Storage & DependencyBuildable
        >(
        configDataSource: ConfigDataSource,
        authenticator: Auth.Type,
        storage: Data.Type,
        services: [SlackService]) throws {
        
        let server = HTTPServerProvider(server: Droplet())
        let http = HTTPProvider()
        let webAPI = WebAPI(http: http)
        let rtmAPI = RTMAPI(websocket: WebSocketProvider())
        
        let config = try Config(
            supportedItems: AllConfigItems(including: authenticator.configItems),
            source: configDataSource
        )
        
        //I miss splatting :(
        let authenticatorInstance = try authenticator.make(
            config: config,
            server: server,
            http: http,
            rtmAPI: rtmAPI,
            webAPI: webAPI
        )
        
        let storageInstance = try storage.make(
            config: config,
            server: server,
            http: http,
            rtmAPI: rtmAPI,
            webAPI: webAPI
        )
        
        self.init(
            config: config,
            authenticator: authenticatorInstance,
            storage: storageInstance,
            webAPI: webAPI,
            rtmAPI: rtmAPI,
            server: server,
            services: services
        )
    }
}

//MARK: - Quick and dirty dependency factory
//This was just a simple way to make building a bot instance and it's dependencies _super_ easy for 99% of use cases
//I don't want to clutter the `App` with everything above
public protocol DependencyBuildable {
    static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI) throws -> Self
}

//MARK: - Authenticators
extension OAuthAuthentication: DependencyBuildable {
    public static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI) throws -> OAuthAuthentication {
        return try OAuthAuthentication(
            config: config,
            server: server,
            http: http
        )
    }
}

extension TokenAuthentication: DependencyBuildable {
    public static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI) throws -> TokenAuthentication {
        return try TokenAuthentication(config: config)
    }
}

//MARK: - Storage
extension MemoryStorage: DependencyBuildable {
    public static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI) throws -> MemoryStorage {
        return MemoryStorage()
    }
}
//extension RedisStorage: DependencyBuildable {
//    public static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI) throws -> RedisStorage {
//        return try RedisStorage(url: try config.value(for: StorageURL.self))
//    }
//}
