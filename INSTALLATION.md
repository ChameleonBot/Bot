# Prerequisites
Please work through the following to get your bot up and running.

## Xcode 8
You will first need Xcode 8, you can download it at [Apple Developer Downloads.](https://developer.apple.com/download/)
After your downlod completes drag it into your `Applications` folder to install it.
Finally you need to select Xcode 8 for your `Command Line Tools`, you can do this from Xcode 8
preferences (`cmd` + `,`). Go to the `Locations` tab, under `Command Line Tools` choose `Xcode 8`

## Swift 3
You need Swift 3 installed, I recommend using [swiftenv](https://github.com/kylef/swiftenv).
Once you have `swiftenv` installed run the following commands in a terminal window.

```
swiftenv install DEVELOPMENT-SNAPSHOT-2016-07-25-a
swiftenv global DEVELOPMENT-SNAPSHOT-2016-07-25-a
```

This will install the snapshot and set it as the default installation of Swift 3.

## Slack
There are two ways to authenticate your bot with slack:

### OAuth
OAuth access will allow you full access to all of Slacks API capabilities 
including `Slash Commands` and `Interactive Buttons`

You will need to [create a new Slack app](https://api.slack.com/apps/new).
Once created go into the `App Credentials` section and add a redirection url. 
It should be the url to your bot with a trailing `/oauth`. 
For example `https://yourbot.yourhost.com/oauth`.
Make sure you copy the client id and secret, you will need them later.

Finally under the `Bot Users` section attach a bot user to the app.

### Token
Token based authentication is simpler however you will *not* 
be able to use `Slash Commands` or `Interactive Buttons`

You will need to [configure](https://my.slack.com/services/new/bot) a new bot user for your team. 
Make sure you copy the token, you will need it later.

## Heroku
If you plan to run a bot on Heroku you will need a [Heroku](https://www.heroku.com/) account (free is fine!) 
and also have the [Heroku Toolbelt](https://toolbelt.heroku.com/) installed. 

<br/>

# Deploying
Start by cloning or downloading the [example bot](https://github.com/ChameleonBot/Example).

## Running locally on OSX
* Open a terminal window and go to the directory containing `Package.swift`
* Type `swift build`
* For token based auth: Type `.build/debug/app --token="<your-bot-token>"`
* For oauth based auth: Type `.build/debug/app --clientId="<your-clientid> --clientSecret="<your-client_secret>"`
* Go into a default channel in your slack and say `hi @yourBot` - it should respond.

## Deploy to Heroku
* Open a terminal window and go to the directory containing `Package.swift`
* Using the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-command) login and create a new app.
* In the Heroku dashboard add config variables for authentication:
    * For token based auth add a variable named `TOKEN` with your slack token
    * For oauth based auth add a variables named `CLIENT_ID` and `CLIENT_SECRET` with your slack client id and secret
* Set the buildpack `heroku buildpacks:set https://github.com/IanKeen/heroku-buildpack-swift`
* Create a file called `Procfile` and add the text: `web: App --config:servers.default.port=$PORT`
* Deploy to Heroku by typing:
```
git add .
git commit -am 'depoy to heroku'
git push heroku master
```
* Once that has completed type: `heroku ps:scale web=1`
* Go into a default channel in your slack and say `hi @yourBot` - it should respond.

<br/>

# Troubleshooting
### OpenSSL Errors on OSX
If you are unable to build/run locally due to an `openssl` error, you may need to run the following in terminal:

```
brew install openssl
brew link openssl
```
