import Config
import Services
import Common
import Foundation

//MARK: - Endpoints
private enum Endpoint: String {
    case login
    case oauth
}

//MARK: - OAuthAuthentication
/// Handles oauth authentication
public final class OAuthAuthentication: SlackAuthenticator {
    //MARK: - Private Properties
    fileprivate let clientId: String
    fileprivate let clientSecret: String
    fileprivate let scopes: Set<String>
    fileprivate let server: HTTPServer
    fileprivate let http: HTTP
    fileprivate let storage: Storage
    
    //MARK: - Private Mutable Properties
    fileprivate var state = ""
    fileprivate var success: ((SlackAuthentication) -> Void)?
    fileprivate var failure: ((Error) -> Void)?
    
    //MARK: - Lifecycle
    public init(clientId: String, clientSecret: String, scopes: [String], server: HTTPServer, http: HTTP, storage: Storage) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.scopes = Set(["bot"] + scopes)
        self.server = server
        self.http = http
        self.storage = storage
        
        self.configureServer()
    }
    public convenience init(config: Config, server: HTTPServer, http: HTTP, storage: Storage) throws {
        let clientId: String = try config.value(for: OAuthClientID.self)
        let clientSecret: String = try config.value(for: OAuthClientSecret.self)
        let scopes: [String] = try config.value(for: Scopes.self)
        
        self.init(
            clientId: clientId,
            clientSecret: clientSecret,
            scopes: scopes,
            server: server,
            http: http,
            storage: storage
        )
    }
    
    //MARK: - Public
    public static var configItems: [ConfigItem.Type] {
        return [OAuthClientID.self, OAuthClientSecret.self, Scopes.self]
    }
    public func authenticate(success: @escaping (SlackAuthentication) -> Void, failure: @escaping (Error) -> Void) {
        if let authentication = self.authentication() {
            success(authentication)
            return
        }
        
        self.state = "\(Int.random(min: 1, max: 999999))"
        self.success = { [weak self] authentication in
            self?.reset()
            success(authentication)
        }
        self.failure = { [weak self] error in
            self?.reset()
            failure(error)
        }
        
        print("Ready to authenticate: Please visit /login")
    }
    public func disconnected() throws {
        try self.clearAuthentication()
    }
    
    //MARK: - State
    private func reset() {
        self.state = ""
        self.success = nil
        self.failure = nil
    }
}

fileprivate extension OAuthAuthentication {
    func authentication() -> OAuthSlackAuthentication? {
        guard
            let values: [String] = self.storage.get(.in("oauth"), key: "token"),
            values.count == 2,
            let bot_access_token = values.first,
            let access_token = values.last
            else { return nil }
        
        return OAuthSlackAuthentication(
            bot_access_token: bot_access_token,
            access_token: access_token
        )
    }
    
    func updateAuthentication(json: [String: Any]) throws -> OAuthSlackAuthentication  {
        let bot_access_token: String = try json.value(at: ["bot", "bot_access_token"])
        let access_token: String = try json.value(at: ["access_token"])
        
        try self.storage.set(.in("oauth"), key: "token", value: [bot_access_token, access_token])
        
        return OAuthSlackAuthentication(
            bot_access_token: bot_access_token,
            access_token: access_token
        )
    }
    
    func clearAuthentication() throws {
        let value: [String]? = nil
        try self.storage.set(.in("oauth"), key: "token", value: value)
    }
}

//MARK: - Server
fileprivate extension OAuthAuthentication {
    func configureServer() {
        self.server.respond(
            to: .get, at: [Endpoint.login.rawValue],
            with: self, OAuthAuthentication.handleLogin
        )
        self.server.respond(
            to: .get, at: [Endpoint.oauth.rawValue],
            with: self, OAuthAuthentication.handleOAuth
        )
    }
    
    func handleLogin(url: URL, headers: [String: String], data: [String: Any]?) throws -> HTTPServerResponse? {
        guard !self.state.isEmpty else { return nil }
        return try self.oAuthAuthorizeURL()
    }
    func handleOAuth(url: URL, headers: [String: String], data: [String: Any]?) throws -> HTTPServerResponse? {
        guard
            let data = url.query?.makeQueryParameters(),
            let state = data["state"],
            let code = data["code"],
            !state.isEmpty, state == self.state
            else { return nil }
        
        if let error = data["error"] { throw OAuthAuthenticationError.oauthError(reason: error) }
        
        _ = inBackground(
            try: {
                let accessUrl = try self.oAuthAccessURL(code: code)
                let request = HTTPRequest(method: .get, url: accessUrl)
                let (_, data) = try self.http.perform(with: request)
                let json = (data as? [String: Any]) ?? [:]
                
                let authentication = try self.updateAuthentication(json: json)
                self.success?(authentication)
            },
            catch: { error in
                self.failure?(error)
            }
        )
        
        return nil
    }
}

//MARK: - URLs
fileprivate extension OAuthAuthentication {
    func oAuthAuthorizeURL() throws -> URL {
        var components = URLComponents(string: "https://slack.com/oauth/authorize")
        
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: self.clientId),
            URLQueryItem(name: "scope", value: self.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: self.state),
        ]
        
        guard let url = components?.url else { throw OAuthAuthenticationError.invalidURL }
        return url
    }
    func oAuthAccessURL(code: String) throws -> URL {
        var components = URLComponents(string: "https://slack.com/api/oauth.access")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: self.clientId),
            URLQueryItem(name: "client_secret", value: self.clientSecret),
            URLQueryItem(name: "code", value: code),
        ]
        
        guard let url = components?.url else { throw OAuthAuthenticationError.invalidURL }
        return url
    }
}
