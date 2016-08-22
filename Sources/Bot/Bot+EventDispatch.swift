import RTMAPI

/// An abstraction that represents an object that can route `RTMAPIEvent`s
public protocol SlackRTMEventDispatcher {
    func onEvent<T: RTMAPIEvent>(_ event: T.Type, handler: (T.Parameters) throws -> Void)
}

extension RTMAPI: SlackRTMEventDispatcher { }
