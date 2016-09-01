# Receiving Slack events

## SlackService API
There are a series of `SlackService` protocols you can use that 
will give you access to Slacks events.

### SlackConnectionService
This service provides you with a function that is called 
once the bot is connected to Slack and gives you 
access to all of the teams data.

```
func connected(slackBot: SlackBot, botUser: BotUser, team: Team, users: [User], channels: [Channel], groups: [Group], ims: [IM]) throws {
    
}
```

### SlackDisconnectionService
This service provides you with a function that is called
when the bot is disconnected from Slack

```
func disconnected(slackBot: SlackBot, error: Error?) {

}
```

### SlackErrorService
This service provides you with a function that is called
when an error occurs, this could be from Slack as well as 
any loaded `SlackService`s.

```
func error(slackBot: SlackBot, error: Error) {

}
```

### SlackRTMEventService
This service provides you with a function that is called when the bot is created.
It gives you access to a `SlackRTMEventDispatcher` object. This event dispatcher can
be used to listen to any event from Slacks [RTM API](https://api.slack.com/rtm).

`RTMAPIEvent`s are named for their [RTM API](https://api.slack.com/events) 
counterparts and can be used as follows:

```
func configureEvents(slackBot: SlackBot, webApi: WebAPI, dispatcher: SlackRTMEventDispatcher) {
    dispatcher.onEvent(message.self) { data in
        print("User: \(data.message.user?.name) said, \(data.message.text)")
    }
    dispatcher.onEvent(error.self) { data in
        print("Error: \(data.message) - Code (\(data.code))")
    }
}
```

The `data` parameter passed along will contain the data specific to each event.

The following events are currently supported:
| Event                |
|----------------------|
| error                |
| hello                |
| pong                 |
| message              |
| presence_change      |
| reconnect_url        |
| user_change          |
| user_typing          |
| channel_marked       |
| channel_created      |
| channel_joined       |
| channel_left         |
| channel_deleted      |
| channel_archive      |
| channel_unarchive    |
| channel_rename       |
| dnd_updated          |
| dnd_updated_user     |
| file_private         |
| file_change          |
| file_created         |
| file_public          |
| file_shared          |
| file_unshared        |
| file_deleted         |
| file_comment_added   |
| file_comment_edited  |
| file_comment_deleted |
| group_joined         |
| group_left           |
| group_open           |
| group_close          |
| group_archive        |
| group_unarchive      |
| group_marked         |
| group_rename         |
| im_close             |
| im_created           |
| im_marked            |
| im_open              |
| reaction_added       |
| reaction_removed     |

### SlackSlashCommandService
This service allows you to respond to /slash commands.

```
struct MySlashCommandService: SlackSlashCommandService {
    let slashCommands = ["/foo", "/bar"]

    func slashCommand(slackBot: SlackBot, command: SlashCommand, webApi: WebAPI) throws {
        if (command.command == "/foo") {
            //handle foo

        } else if (command.command == "/bar") {
            //handle bar
        }
    }
}
```

`command` is a `SlashCommand` containing all the data associated with the command.

<br/>

# Posting to Slack
Once you have received an event you will probably want to post message back to Slack.
To do this you can use the `WebAPI` instance that is provided to each service.

```
func configureEvents(slackBot: SlackBot, webApi: WebAPI, dispatcher: SlackRTMEventDispatcher) {
    dispatcher.onEvent(message.self) { data in
        guard 
            let target = data.message.channel?.value,
            let text = data.message.text,
            !text.isEmpty
            else { return }

        let request = ChatPostMessage(target: target, text: "ECHO: \(text))
        try webApi.execute(request)
    }
}
```

For slash commands you are provided with a response url that you can use to respond.

```
func slashCommand(slackBot: SlackBot, command: SlashCommand, webApi: WebAPI) throws {
    if (command.command == "/myCommand") {
        guard
            let channel = command.channel,
            let url = URL(string: command.response_url)
            else { return }
        
        let request = ChatPostMessage(
            target: target, 
            text: "Command parameters: \(command.text)", 
            customUrl: url
        )
        try webApi.execute(request)
    }
}
```

Check out [Sugar](https://github.com/ChameleonBot/Sugar) for some syntactic sugar
you can use to make some common tasks a little easier.
