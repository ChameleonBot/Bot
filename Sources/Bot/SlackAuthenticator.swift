import Config
import WebAPI

/// Abstraction representing a means for the `SlackBot` to authenticate.
public protocol SlackAuthenticator {
    /// Config items required by this `SlackAuthenticator`
    static var configItems: [ConfigItem.Type] { get }
    
    /**
     Authenticate the `SlackBot`
     
     - parameter success:   This closure fires with the `SlackAuthentication` needed for the `SlackBot` to authenticate
     - parameter failure:   This closure fires with the reason the authentication attempt failed
     */
    func authenticate(success: @escaping (SlackAuthentication) -> Void, failure: @escaping (Error) -> Void)
    
    /**
     The `SlackBot` was disconnected, this allows any cleanup to be performed
     */
    func disconnected() throws
}
