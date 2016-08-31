# SlackService API
There are a series of `SlackService` protocols you can use that 
will give you access to Slacks APIs.

## SlackConnectionService
This service provides you with a function that is called 
once the bot is connected to Slack and gives you 
access to all of the teams data.

```
func connected(slackBot: SlackBot, botUser: BotUser, team: Team, users: [User], channels: [Channel], groups: [Group], ims: [IM]) throws {
    
}
```

## SlackDisconnectionService
This service provides you with a function that is called
when the bot is disconnected from Slack

```
func disconnected(slackBot: SlackBot, error: Error?) {

}
```

## SlackErrorService
This service provides you with a function that is called
when an error occurs, this could be from Slack as well as 
any loaded `SlackService`s.

```
func error(slackBot: SlackBot, error: Error) {

}
```

## SlackRTMEventService
This service provides you with a function that is called when the bot is created.
It gives you access to a `SlackRTMEventDispatcher` object. This event dispatcher can
be used to listen to any event from Slacks [RTM API](https://api.slack.com/rtm).

..

```
func configureEvents(slackBot: SlackBot, webApi: WebAPI, dispatcher: SlackRTMEventDispatcher) {

}
```