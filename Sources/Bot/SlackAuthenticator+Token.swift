import Config
import Common

public struct TokenSlackAuthentication: SlackAuthentication {
    fileprivate let token: String
    
    public func token<T: WebAPIMethod>(for method: T) throws -> String {
        //token based authentication automatically unlocks all WebAPI methods
        return token
    }
}

/// Handles direct token authentication
public struct TokenAuthentication: SlackAuthenticator {
    //MARK: - Private
    private let authentication: TokenSlackAuthentication
    
    //MARK: - Lifecycle
    public init(token: String) {
        self.authentication = TokenSlackAuthentication(token: token)
    }
    public init(config: Config) throws {
        let token: String = try config.value(for: Token.self)
        self.init(token: token)
    }
    
    //MARK: - Public
    public static var configItems: [ConfigItem.Type] {
        return [Token.self]
    }
    public func authenticate(success: @escaping (SlackAuthentication) -> Void, failure: @escaping (Error) -> Void) {
        success(self.authentication)
    }
    public func disconnected() { }
}
