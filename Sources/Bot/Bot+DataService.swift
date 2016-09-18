
extension SlackBot {
    final class DataService: SlackRTMEventService {
        func configureEvents(slackBot: SlackBot, webApi: WebAPI, dispatcher: SlackRTMEventDispatcher) {
            dispatcher.onEvent(team_join.self) { user in
                slackBot.users.append(user)
            }
        }
    }
}
