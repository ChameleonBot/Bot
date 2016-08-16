import Config
import Common

import Foundation

/// Handles direct token authentication
public struct TokenAuthentication: SlackAuthenticator {
    //MARK: - Private
    private let token: String
    
    //MARK: - Lifecycle
    public init(token: String) {
        self.token = token
    }
    public init(config: Config) throws {
        self.token = try config.value(for: Token.self)
    }
    
    //MARK: - Public
    public static var configItems: [ConfigItem.Type] {
        return [Token.self]
    }
    public func authenticate(success: (token: String) -> Void, failure: (error: Error) -> Void) {
        success(token: self.token)
    }
}
