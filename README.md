# Oskar - the Slack satisfaction coach

[![Build Status](https://travis-ci.org/wearehanno/oskar.svg?branch=master)](https://travis-ci.org/wearehanno/oskar)

## Description

Oskar is a Slackbot that tracks satisfaction of your team members. Every day it asks people how they're doing. This metric is stored in a database and tracked over time, allowing the team to understand which members are struggling or doing extremely well.

Everyone on your team can ask Oskar for another team member's or the entire team's current status. It is not meant to be a way of comparing people but to surface issues, unblock each other and eliminate isolation (especially in remote teams).

## Installing him on Heroku

You can deploy your own copy to Heroku with one click using this button:

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

See the [Heroku documentation](https://devcenter.heroku.com/articles/config-vars) for more info about changing the configuration variables after deployment.

## Using the bot

Oskar automatically asks you two times a day how you're doing. You can reply to him with a number between 1 to 5, and he will then ask you for feedback to know what's the trigger for your current low or high.

All data is collected in a database and made visible via the dashboard, which can be found at the URL:
`http://your-oskar-url.com/dashboard` (find instruction on how to set a username/password below)

If you're hosting on Heroku, then this URL is going to be something like _http://myherokuappname.herokuapp.com/dashboard_.

You can send the following commands directly as a chat message to Oskar:
- `How is @member?` - Tells you how a specific team member is doing
- `How is @channel?` - Returns the current status for the whole group

# The App

## Tech stack

- Oskar is build on node.js with express.js.
- It is written in CoffeeScript (such as the node slack client it uses)
- It uses a MongoDB database to store team member feedback
- It (usually, but not only) runs on Heroku

## Configuring Oskar

There are two ways of configuring Oskar.

1) Using local configuration:
You copy the contents of the file `config/default.json` and create a new file `config/local.json` with your environment's variables.

2) Using Heroku env variables:
Use `.env.sample` to set up your Heroku env variables, either setting them via the command line (as described [here](https://devcenter.heroku.com/articles/config-vars)) or directly from the Heroku panel.

Here's the config variables you need to define:
- `mongo.url` (or `MONGOLAB_URI` for Heroku) defines the url to your MongoDB database (to create a mongoDB on Heroku, go to https://elements.heroku.com/addons/mongolab). This will be automatically generated if you create a MongoLab database as described below ("Setting up Oskar on Heroku") in step 4.
- `slack.token` (or `SLACK_TOKEN` for Heroku) is the token of your team's Slackbot (you can create a new Slackbot here: https://yourteam.slack.com/services/new/bot)

If you want to broadcast all user feedback to a channel instead of to each user individually:
- `slack.channelId` (or `CHANNEL_ID` for Heroku) defines the channel where Oskar will broadcast all user messages. Add this parameter if you don't want Oskar to send the status feedback to each user's direct message channel. On Heroku, don't add quotes around the parameter, just the channel ID: CXXXXXX

Additionally you can disable specific channels or users:
- `slack.disabledUsers` (or `DISABLED_USERS` for Heroku) to disable **users** if you want specific people on your team to not receive any Oskar messages at all (Go here to find out your user IDs: https://api.slack.com/methods/users.list/test). When using Heroku, make sure to put the list IDs into quotes like this: "UXXXXXX", "UYYYYYY"
- `slack.disabledChannels` (or `DISABLED_CHANNELS` for Heroku) to disable **channels** that Oskar is part of (Go here to find out your channel IDs: https://api.slack.com/methods/channels.list/test). When using Heroku, make sure to put the user IDs into quotes like this: "CXXXXXX", "CYYYYYY"

By default your dashboard is protected via a simple HTTP auth mechanism. (we'll try to improve this in the future)
- `auth.username` and `auth.password` (or `AUTH_USERNAME` and `AUTH_PASSWORD` for Heroku) define your login data for the dashboard. Make sure to share those with your team.

See the following instructions if you set up Oskar for the first time.

# Development and Contributing

## Local environment quickstart

First, we need to install MongoDB if you don't have it running already. Full instructions are [here](http://docs.mongodb.org/manual/installation/):

    $ brew install mongodb
    # Create a data folder to store MongoDB databases
    $ sudo mkdir -p /data/db
    $ sudo chown $USER /data/db

Now we're running, we can initialise the database:

    $ mongod

After making sure that MongoDB is running on port 27071, build the app as follows:

- Download and install nodeJS: https://nodejs.org/download/
- Install Grunt: `npm install grunt -g`
- Run `npm install` to install dependencies
- Run `grunt prepublish` to build the app: this copies the source files over to the `target` folder and compiles CoffeeScript to JavaScript
- Start the local app using Heroku Foreman, with: `foreman start web`
- You can reach the site at http://localhost:5000
- Compile & watch CoffeeScript and SASS files using `grunt watch`

## Unit tests

Oskar is being tested with [Mocha](http://mochajs.org/) and [should.js](https://github.com/tj/should.js/)
For the mongo tests to pass, you'll have to run a mongo database under `mongodb://localhost:27017`.

Run the unit tests for all modules:

    $ npm test

To run only a single unit test call the test file explicitly, such as `npm test test/inputHelper.coffee`