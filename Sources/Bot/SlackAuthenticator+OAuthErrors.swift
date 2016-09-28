
/// Describes the range of possible errors that can occur when authenticating using OAuth
public enum OAuthAuthenticationError: Error, CustomStringConvertible {
    /// A derived url was invalid
    case invalidURL
    
    /// An oAuth error
    case oauthError(reason: String)
    
    public var description: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .oauthError(let reason): return "OAuth Failed: \(reason)"
        }
    }
}
