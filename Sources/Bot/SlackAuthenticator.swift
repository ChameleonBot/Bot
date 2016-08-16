import Config

/// Abstraction representing a means for the `SlackBot` to authenticate.
public protocol SlackAuthenticator {
    /**
     Authenticate the `SlackBot`
     
     - parameter success:   This closure fires with the token needed for the `SlackBot` to authenticate
     - parameter failure:   This closure fires with the reason the authentication attempt failed
     */
    func authenticate(success: (token: String) -> Void, failure: (error: Error) -> Void)
    
    static var configItems: [ConfigItem.Type] { get }
}
