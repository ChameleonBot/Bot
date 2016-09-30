@_exported import Config
@_exported import Services
@_exported import WebAPI
@_exported import RTMAPI
@_exported import Models
@_exported import Common
import Foundation

/// An extensible Slack bot user than can provide custom functionality
public class SlackBot {
    //MARK: - Private Properties
    fileprivate let config: Config
    fileprivate let server: HTTPServer
    fileprivate let state: BotStateMachine
    fileprivate let authenticator: SlackAuthenticator
    fileprivate var services: [SlackService] = [DataService()]
    
    //MARK: - Internal Dependencies
    internal let webAPI: WebAPI
    internal let rtmAPI: RTMAPI
    
    //MARK: - Internal Data
    internal var botUser: BotUser?
    internal var team: Team?
    internal var users: [User] = []
    internal var channels: [Channel] = []
    internal var groups: [Group] = []
    internal var ims: [IM] = []
    //internal fileprivate(set) var mpims: [MPIM] = []
    
    //MARK: - Public Properties
    public private(set) var storage: Storage
    public private(set) var http: HTTP
    
    //MARK: - Lifecycle
    /**
     Creates a new `SlackBot` instance
     
     - parameter config:        The `Config` with the configuration for this instance
     - parameter authenticator: The `SlackAuthenticator` used to obtain a token for the bot to use
     - parameter storage:       The `Storage` implementation used for simple key/value storage
     - parameter http:          The `HTTP` available to `SlackService`s for making http requests
     - parameter webAPI:        The `WebAPI` used for interaction with the Slack WebAPI
     - parameter rtmAPI:        The `RTMAPI` used for interaction with the Slack Real-time messaging api
     - parameter server:        The `HTTPServer` used to handle Web based interactions
     - parameter services: A sequence of `SlackService`s that provide this bots functionality
     
     - returns: A new `SlackBot` instance
     */
    public required init(
        config: Config,
        authenticator: SlackAuthenticator,
        storage: Storage,
        http: HTTP,
        webAPI: WebAPI,
        rtmAPI: RTMAPI,
        server: HTTPServer,
        services: [SlackService]) {
        
        self.config = config
        self.authenticator = authenticator
        self.http = http
        self.server = server
        self.webAPI = webAPI
        self.rtmAPI = rtmAPI
        self.storage = storage
        self.services.append(contentsOf: services)
        
        self.state = BotStateMachine(startingWith: .disconnected(error: nil))
        self.state.observe(self, transition: SlackBot.botStateTransition)
        
        self.webAPI.slackModels = self.currentSlackModelData
        self.rtmAPI.slackModels = self.currentSlackModelData
        
        self.bindToRTM()
        self.configureServer()
        self.configureEventServices()
    }
    
    //MARK: - Public Functions
    /// Start the bot
    public func start() {
        self.server.start(mode: .newThread)
        
        do {
            let maximumAttempts: Int = try self.config.value(for: ReconnectionAttempts.self)
            self.state.transition(withEvent: .connect(maximumAttempts: maximumAttempts))
            
        } catch let error {
            self.state.transition(withEvent: .disconnect(reconnect: true, error: error))
        }
        
        keepAlive {
            switch self.state.state {
            case .disconnected: return true
            default: return false
            }
        }
        
        self.authenticator.disconnected()
    }
}

//MARK: - State Transitions
fileprivate extension SlackBot {
    func botStateTransition(change: StateChange<BotState>) {
        print("STATE: \(change)")
        
        switch change.new {
        case .connecting: //(attempt: <#T##Int#>, maximumAttempts: <#T##Int#>):
            self.obtainTokenForWebAPI {
                self.connectToRTM()
            }
            
        case .connected: //(state: <#T##BotState.ConnectedState#>, maximumReconnectionAttempts: <#T##Int#>):
            guard change.new.ready else { return }
            print("ME: \(self.botUser)")
            self.notifyConnected()
            
        case .disconnected(let error):
            self.rtmAPI.disconnect()
            self.notifyDisconnected(error)
        }
    }
}

//MARK: - Model Data
extension SlackBot {
    public func currentSlackModelData() -> SlackModels {
        return (
            users: self.users,
            channels: self.channels,
            groups: self.groups,
            ims: self.ims,
            team: self.team
        )
    }
    public func currentBotUserAndTeam() -> (BotUser, Team) {
        guard
            let botUser = self.botUser,
            let team = self.team
            else { fatalError("Something went wrong, we should have botUser and team data at this point!") }
        
        return (botUser, team)
    }
}

//MARK: - Authentication
fileprivate extension SlackBot {
    func obtainTokenForWebAPI(complete: @escaping () -> Void) {
        self.authenticator.authenticate(
            success: { [weak self] authentication in
                self?.webAPI.authentication = authentication
                print("AUTHENTICATION: \(authentication)")
                complete()
            },
            failure: { [weak self] error in
                self?.state.transition(withEvent: .disconnect(reconnect: true, error: error))
            }
        )
    }
}

//MARK: - RTMAPI
fileprivate extension SlackBot {
    func bindToRTM() {
        self.rtmAPI.onDisconnected = { [weak self] error in
            self?.state.transition(withEvent: .disconnect(reconnect: true, error: error))
        }
        self.rtmAPI.onError = { [weak self] error in
            self?.notifyError(error)
        }
        self.rtmAPI.onEvent(hello.self) { [weak self] in
            self?.state.transition(withEvent: .connectionState(state: .Hello))
        }
    }
    func connectToRTM() {
        do {
            let options: [RTMStartOption] = try self.config.value(for: RTMStartOptions.self)
            let rtmStart = RTMStart(options: options) { [weak self] serializedData in
                guard let `self` = self else { return }
                
                do {
                    let (botUser, team, users, channels, groups, ims) = try serializedData()
                    
                    self.botUser = botUser
                    self.team = team
                    self.users = users
                    self.channels = channels
                    self.groups = groups
                    self.ims = ims
                    
                    self.state.transition(withEvent: .connectionState(state: .Data))
                    
                } catch let error {
                    self.state.transition(withEvent: .disconnect(reconnect: true, error: error))
                }
            }
            let RTMURL = try self.webAPI.execute(rtmStart)
            let pingPongInterval: Double = try self.config.value(for: PingPongInterval.self)
            try self.rtmAPI.connect(to: RTMURL, pingPongInterval: pingPongInterval)
            
        } catch let error {
            self.state.transition(withEvent: .disconnect(reconnect: true, error: error))
        }
    }
}

//MARK: - HTTPServer
fileprivate extension SlackBot {
    enum Endpoint: String {
        case status
        case slashCommand
        case interactiveButton
        
        static var all: [Endpoint] { return [.status, .slashCommand, .interactiveButton] }
        
        var method: HTTPRequestMethod {
            switch self {
            case .status: return .get
            case .slashCommand: return .post
            case .interactiveButton: return .post
            }
        }
        var handler: (SlackBot) -> RouteHandler {
            switch self {
            case .status: return SlackBot.statusHandler
            case .slashCommand: return SlackBot.slashCommandHandler
            case .interactiveButton: return SlackBot.interactiveButtonHandler
            }
        }
    }
    
    func configureServer() {
        self.server.onError = { [weak self] error in
            self?.notifyError(error)
        }
        
        for endpoint in Endpoint.all {
            self.server.respond(
                to: endpoint.method, at: [endpoint.rawValue],
                with: self, endpoint.handler
            )
        }
    }
    func statusHandler(url: URL, headers: [String: String], json: [String: Any]?) throws -> HTTPServerResponse? {
        return nil //empty 200
    }
    func slashCommandHandler(url: URL, headers: [String: String], json: [String: Any]?) throws -> HTTPServerResponse? {
        guard self.state.state.ready, let json = json else { return nil }
        
        let builder = SlackModelBuilder.make(models: self.currentSlackModelData())
        let slashCommand = try SlashCommand.makeModel(with: builder(json))
        self.notifySlashCommand(slashCommand)
        
        return nil
    }
    func interactiveButtonHandler(url: URL, headers: [String: String], json: [String: Any]?) throws -> HTTPServerResponse? {
        guard
            self.state.state.ready,
            let json = json,
            let payload = json["payload"] as? String
            else { return nil }
        
        let builder = SlackModelBuilder.make(models: self.currentSlackModelData())
        let packet = payload.makeDictionary()
        let response = try InteractiveButtonResponse.makeModel(with: builder(packet))
        self.notifyInteractiveButton(response)
        
        return nil
    }
}

//MARK: - Event Propogation
fileprivate extension SlackBot {
    func configureEventServices() {
        let services = self.services.flatMap { $0 as? SlackRTMEventService }
        
        for service in services {
            service.configureEvents(slackBot: self, webApi: self.webAPI, dispatcher: self.rtmAPI)
        }
    }
    
    func notifyConnected() {
        let services = self.services.flatMap { $0 as? SlackConnectionService }
        
        let (users, channels, groups, ims, _) = self.currentSlackModelData()
        let (botUser, team) = self.currentBotUserAndTeam()
        
        do {
            for service in services {
                try service.connected(
                    slackBot: self,
                    botUser: botUser,
                    team: team,
                    users: users,
                    channels: channels,
                    groups: groups,
                    ims: ims
                )
            }
            
        } catch let error {
            self.notifyError(error)
        }
    }
    func notifyDisconnected(_ error: Error?) {
        let services = self.services.flatMap { $0 as? SlackDisconnectionService }
        
        for service in services {
            service.disconnected(slackBot: self, error: error)
        }
    }
    func notifyError(_ error: Error) {
        print("ERROR: \(error)")
        guard self.state.state.ready else { return }
        
        let services = self.services.flatMap { $0 as? SlackErrorService }
        
        for service in services {
            service.error(slackBot: self, error: error)
        }
    }
    func notifySlashCommand(_ command: SlashCommand) {
        guard self.state.state.ready else { return }
        
        do {
            let verificationToken: String = try self.config.value(for: VerificationToken.self)
            
            let services = self.services.flatMap { $0 as? SlackSlashCommandService }
            
            for service in services {
                let noMatch = service
                    .slashCommands
                    .filter { $0.with(prefix: "/") == command.command && verificationToken == command.token }
                    .isEmpty
                
                if (!noMatch) {
                    try service.slashCommand(
                        slackBot: self,
                        webApi: self.webAPI,
                        command: command
                    )
                }
            }
            
        } catch let error {
            self.notifyError(error)
        }
    }
    func notifyInteractiveButton(_ response: InteractiveButtonResponse) {
        guard self.state.state.ready else { return }
        
        do {
            let verificationToken: String = try self.config.value(for: VerificationToken.self)
            guard verificationToken == response.token else { return }
            
            let services = self.services.flatMap { $0 as? SlackInteractiveButtonService }
            
            for service in services {
                try service.interactiveButton(
                    slackBot: self,
                    webApi: self.webAPI,
                    response: response
                )
            }
            
        } catch let error {
            self.notifyError(error)
        }
    }
}
