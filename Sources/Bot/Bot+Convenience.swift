import class Vapor.Droplet

/*
 
 I write messy boilerplate so you don't have to ;)
 
 */

public extension SlackBot {
    public convenience init<
        Auth: SlackAuthenticator & DependencyBuildable,
        Data: Storage & ConfigBuildable
        >(
        configDataSource: ConfigDataSource,
        configItems: [ConfigItem.Type] = [],
        authenticator: Auth.Type,
        storage: Data.Type,
        services: [SlackService]) throws {
        
        let server = HTTPServerProvider()
        let http = HTTPProvider()
        let webAPI = WebAPI(http: http)
        let rtmAPI = RTMAPI(websocket: WebSocketProvider())
        
        let config = try Config(
            supportedItems: AllConfigItems(including: configItems + authenticator.configItems),
            source: configDataSource
        )
        
        //I miss splatting :(
        let storageInstance = try storage.make(
            config: config
        )
        
        let authenticatorInstance = try authenticator.make(
            config: config,
            server: server,
            http: http,
            rtmAPI: rtmAPI,
            webAPI: webAPI,
            storage: storageInstance
        )
        
        self.init(
            config: config,
            authenticator: authenticatorInstance,
            storage: storageInstance,
            http: http,
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
    static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI, storage: Storage) throws -> Self
}

public protocol ConfigBuildable {
    static func make(config: Config) throws -> Self
}


//MARK: - Authenticators
extension OAuthAuthentication: DependencyBuildable {
    public static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI, storage: Storage) throws -> OAuthAuthentication {
        return try OAuthAuthentication(
            config: config,
            server: server,
            http: http,
            storage: storage
        )
    }
}

extension TokenAuthentication: DependencyBuildable {
    public static func make(config: Config, server: HTTPServer, http: HTTP, rtmAPI: RTMAPI, webAPI: WebAPI, storage: Storage) throws -> TokenAuthentication {
        return try TokenAuthentication(config: config)
    }
}

//MARK: - Storage
extension MemoryStorage: ConfigBuildable {
    public static func make(config: Config) throws -> MemoryStorage {
        return MemoryStorage()
    }
}
extension RedisStorage: ConfigBuildable {
    public static func make(config: Config) throws -> RedisStorage {
        return try RedisStorage(url: try config.value(for: StorageURL.self))
    }
}
