OskarTexts   = require '../content/oskarTexts'
basicAuth    = require 'basic-auth-connect'
config       = require 'config'

routes = (app, mongo, slack) ->

  app.get '/', (req, res) =>
    res.render 'pages/index'

  app.get '/faq', (req, res) =>
    res.render 'pages/faq'

  app.get '/signup', (req, res) =>
    res.render 'pages/signup'

  app.get '/thank-you', (req, res) =>
    res.render 'pages/thank-you'

  # protect dashboard from external access
  username = process.env.AUTH_USERNAME || config.get 'auth.username'
  password = process.env.AUTH_PASSWORD || config.get 'auth.password'
  auth = basicAuth username, password

  # dashboard
  app.get '/dashboard', auth, (req, res) =>

    # read users
    users = slack.getUsers()

    if users.length is 0
      res.render('pages/dashboard')

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
        users.sort (a, b) ->
          filteredStatuses[a.id].status > filteredStatuses[b.id].status

      res.render('pages/dashboard', { users: users, statuses: filteredStatuses })

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

module.exports = routes