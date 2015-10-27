OskarTexts   = require '../content/oskarTexts'
basicAuth    = require 'basic-auth-connect'
bodyParser   = require 'body-parser'
config       = require 'config'

jsonParser   = bodyParser.json()

routes = (app, mongo, slack) ->

  # protect dashboard from external access
  username = process.env.AUTH_USERNAME || config.get 'auth.username'
  password = process.env.AUTH_PASSWORD || config.get 'auth.password'
  auth = basicAuth username, password

  # dashboard
  app.get '/', auth, (req, res) =>

    # read users
    users = slack.getUsers()

    if users.length is 0
      res.render('pages/index')

    userIds = users.map (user) ->
      return user.id

    # read users status
    mongo.getAllUserFeedback(userIds).then (statuses) =>

      filteredStatuses = []

      if statuses.length
        statuses.forEach (status) ->
          filteredStatuses[status.id]              = status.feedback
          filteredStatuses[status.id].date         = new Date status.feedback.timestamp
          filteredStatuses[status.id].statusString = OskarTexts.statusText[status.feedback.status]

        # only sort when more than one user
        if statuses.length > 1
          users.sort (a, b) ->
            filteredStatuses[a.id].status > filteredStatuses[b.id].status

      res.render('pages/index', { users: users, statuses: filteredStatuses })

  app.get '/signup', (req, res) =>
    res.render 'pages/signup'

  app.get '/thank-you', (req, res) =>
    res.render 'pages/thank-you'

  # user status
  app.get '/status/:userId', (req, res) =>
    mongo.getUserData(req.params.userId).then (data) =>
      graphData = data.feedback.map (row) ->
        return [row.timestamp, parseInt(row.status)]


      userData              = slack.getUser data.id
      userData.status       = data.feedback[data.feedback.length - 1]
      userData.date         = new Date userData.status.timestamp
      userData.statusString = OskarTexts.statusText[userData.status.status]

      res.render('pages/status', { userData: userData, graphData: JSON.stringify(graphData) })

  # message user
  app.post '/message/:userId', jsonParser, (req, res) =>
    if !req.body.message
      return res.status(400).send({ status: 'fail' })
    slack.postMessage req.params.userId, req.body.message
    res.json( { status: 'ok' } )

module.exports = routes