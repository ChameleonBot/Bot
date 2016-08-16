import Common

//MARK: - Typealiase
typealias BotStateMachine = StateMachine<BotState, BotStateEvent>

//MARK: - States
/// Defines the states the bot will move through during connection
enum BotState {
    /**
     *  The bot is disconnected
     *
     *  @param Error? Exists when the disconnection was the result of an error
     */
    case disconnected(error: Error?)
    
    /**
     *  The bot is attempting to connect
     *
     *  @param Int The attempt number
     *  @param Int The maximum number of attempts
     */
    case connecting(attempt: Int, maximumAttempts: Int)
    
    /**
     *  The bot is connected.
     *  NOTE: There are two things that need to happen for the bot to be considered 'ready'
     *
     *  1. We need to receive the `.hello` event from the `RTMAPI`
     *  2. The `RTMStart` WebAPI method has to deserialise the Slack teams models
     *
     *  Because `RTMStart` is performed asynchronously the order of 1 & 2 are not guaranteed
     *  so we use a nested `OptionSet` to keep track of each event.
     *
     *  @param ConnectedState The nested `OptionSet` with the current `ConnectedState`
     */
    case connected(state: ConnectedState, maximumReconnectionAttempts: Int)
    
    /// Sub-states available for the .connected state
    struct ConnectedState: OptionSet {
        let rawValue: Int
        init(rawValue: Int) { self.rawValue = rawValue }
        static let Hello = ConnectedState(rawValue: 1)
        static let Data = ConnectedState(rawValue: 2)
    }
}

//MARK: - Events
enum BotStateEvent {
    /// Disconnect the bot
    case disconnect(reconnect: Bool, error: Error?)
    
    /// Update the connection state
    case connect(maximumAttempts: Int)
    
    /// Update teh connection state
    case connectionState(state: BotState.ConnectedState)
}

//MARK: - Transitions
extension BotState: StateRepresentable {
    typealias StateEvent = BotStateEvent
    
    func transition(withEvent event: BotStateEvent) -> BotState? {
        switch (self, event) {
            
        //Disconnected >
        case (.disconnected, .connect(let maximumAttempts)):
            return .connecting(attempt: 1, maximumAttempts: maximumAttempts)
            
        //Connecting >
        case (.connecting(_, let maximumAttempts), .connectionState(let state)):
            return self.connectedWith(state: state, maximumReconnectionAttempts: maximumAttempts)

        case (.connecting(let attempt, let maximumAttempts), .disconnect(let reconnect, let error)):
            if (attempt < maximumAttempts && reconnect) {
                return .connecting(attempt: attempt + 1, maximumAttempts: maximumAttempts)
            } else {
                return .disconnected(error: error)
            }
            
        //Connected >
        case (.connected(_, let maximumReconnectionAttempts), .disconnect(let reconnect, let error)):
            if (reconnect) {
                return .connecting(attempt: 1, maximumAttempts: maximumReconnectionAttempts)
            } else {
                return .disconnected(error: error)
            }
            
        case (.connected(_, let maximumAttempts), .connectionState(let state)):
            return self.connectedWith(state: state, maximumReconnectionAttempts: maximumAttempts)
            
        //Default
        default: return nil
        }
    }
}

//MARK: - Derrived State
extension BotState {
    /**
     Defines whether all requirements for the bot to be considered ready have completed
     
     - seealso: For more information on the requirements see: `State.Connected(state:)`
     */
    var ready: Bool {
        switch self {
        case .connected(let state, _):
            return state.contains(.Hello) && state.contains(.Data)
            
        default:
            return false
        }
    }
    
    /**
     Updates the nested `ConnectedState` for the `State.Connected` parent state
     
     - parameter new: The `ConnectedState` that has been completed
     - returns: An updated `State` value
     */
    func connectedWith(state new: BotState.ConnectedState, maximumReconnectionAttempts: Int) -> BotState {
        var current = self
        switch self {
        case .connected(let state, _):
            current = .connected(state: state.union(new), maximumReconnectionAttempts: maximumReconnectionAttempts)
        default:
            current = .connected(state: new, maximumReconnectionAttempts: maximumReconnectionAttempts)
        }
        return current
    }
}

//MARK: - Equatable
func ==(lhs: BotState, rhs: BotState) -> Bool {
    switch (lhs, rhs) {
    case (.disconnected, .disconnected): return true
    case (.connecting(let lhs_attempt, _), .connecting(let rhs_attempt, _)): return (lhs_attempt == rhs_attempt)
    case (.connected(let lhs_state), .connected(let rhs_state)): return lhs_state == rhs_state
    default: return false
    }
}

//MARK: - CustomStringConvertible
extension BotState: CustomStringConvertible {
    var description: String {
        switch self {
        case .disconnected(let error):
            let errorString = (error == nil ? "" : ": Error: \(error!)")
            return "Disconnected\(errorString)"
        case .connecting(let attempt, let maximumAttempts):
            return "Connecting: Attempt \(attempt) of \(maximumAttempts)"
        case .connected(let state, _):
            return "Connected: \(state.description)"
        }
    }
}
extension BotState.ConnectedState: CustomStringConvertible {
    var description: String {
        let strings = ["Hello", "Data"]
        let values: [BotState.ConnectedState] = [.Hello, .Data]
        
        return values
            .enumerated()
            .flatMap { index, value in
                guard self.contains(value) else { return nil }
                return strings[index]
            }
            .joined(separator: ",")
    }
}
