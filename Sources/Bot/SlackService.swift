import Models
import RTMAPI
import WebAPI

/// An empty abstraction used to provide a 'base' for each type of supported service
public protocol SlackService { }

/// An abstraction that represents the 'connection' event
public protocol SlackConnectionService: SlackService {
    /**
     Called when the bot has finished conenction to Slack and all the data is ready
     
     - parameter slackBot: The `SlackBot` instance
     - parameter botUser:  The `BotUser` representing the `SlackBot`
     - parameter team:     The `Team` conencted to
     - parameter users:    The teams `User`s
     - parameter channels: The `Channel`s visible to the bot
     - parameter groups:   The `Group`s the bot is in
     - parameter ims:      The `IM`s with the bot
     */
    func connected(
        slackBot: SlackBot,
        botUser: BotUser,
        team: Team,
        users: [User],
        channels: [Channel],
        groups: [Group],
        ims: [IM]
    ) throws
}

/// An abstraction that represents the 'disconnection' event
public protocol SlackDisconnectionService: SlackService {
    /**
     Called when the bot disconnects
     
     - parameter slackBot: The `SlackBot` instance
     - parameter error:    The `Error` _if_ the disconnection was a result of an error
     */
    func disconnected(slackBot: SlackBot, error: Error?)
}

/// An abstraction that represents the 'error' event
public protocol SlackErrorService: SlackService {
    /**
     Called when the bot encounters an error
     
     - parameter slackBot: The `SlackBot` instance
     - parameter error:    The `Error` describing the details
     */
    func error(slackBot: SlackBot, error: Error)
}

/// An abstraction that represents any `RTMAPI` event
public protocol SlackRTMEventService: SlackService {
    /**
     Called once during bot creation, allows service to subscribe to the `RTMAPIEvent`s it needs
     
     - parameter slackBot: The `SlackBot` instance
     - parameter webApi:   The current `WebAPI` that can be used to interact with Slack
     - parameter event:    The `SlackRTMEventDispatcher` that can be used to subscribe to `RTMAPIEvent`s
     */
    func configureEvents(slackBot: SlackBot, webApi: WebAPI, dispatcher: SlackRTMEventDispatcher)
}

/// An abstraction that represents a slash command handler
public protocol SlackSlashCommandService: SlackService {
    /**
     The commands supported by this `SlackSlashCommandService` instance
     */
    var slashCommands: [String] { get }
    
    /**
     Called when one of the registered slash commands is triggered
     
     - parameter slackBot:      The `SlackBot` instance
     - parameter webApi:        The current `WebAPI` that can be used to interact with Slack
     - parameter slashCommand:  The `SlashCommand` with the command details
     */
    func slashCommand(slackBot: SlackBot, webApi: WebAPI, command: SlashCommand) throws
}

/// An abstraction that represents a interactive button handler
public protocol SlackInteractiveButtonService: SlackService {
    /**
     Called when an interactive button response is received
     
     - parameter slackBot:      The `SlackBot` instance
     - parameter webApi:        The current `WebAPI` that can be used to interact with Slack
     - parameter response:      The `InteractiveButtonResponse` with the response details
     */
    func interactiveButton(slackBot: SlackBot, webApi: WebAPI, response: InteractiveButtonResponse) throws
}

