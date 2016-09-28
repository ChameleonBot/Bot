import WebAPI
import Common

public struct OAuthSlackAuthentication: SlackAuthentication {
    let bot_access_token: String
    let access_token: String
    
    public func token<T: WebAPIMethod>(for method: T) throws -> String {
        if (method.requiredScopes.isEmpty) {
            return self.bot_access_token
        }
        return self.access_token
    }
}

//fileprivate extension OAuthSlackAuthentication {
//    var elevatedScopes: [WebAPIScope] {
//        return [
//            .channels_history,
//            .channels_write,
//            .chat_write_bot,
//            .chat_write_user,
//            .emoji_read,
//            .groups_write,
//            .groups_history,
//            .pins_read,
//        ]
//    }
//}
