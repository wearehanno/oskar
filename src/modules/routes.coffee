OskarTexts   = require '../content/oskarTexts'
basicAuth    = require 'basic-auth-connect'
bodyParser   = require 'body-parser'
config       = require 'config'

jsonParser   = bodyParser.json()

routes = (app, mongo, slack) ->

  # app.get '/', (req, res) =>
  #   console.log "GET /"
  #   res.render 'pages/index'

  app.get '/faq', (req, res) =>
    console.log "GET /faq"
    res.render 'pages/faq'

  # protect dashboard from external access
  username = process.env.AUTH_USERNAME || config.get 'auth.username'
  password = process.env.AUTH_PASSWORD || config.get 'auth.password'
  auth = basicAuth username, password

  # dashboard
  app.get '/', auth, (req, res) =>
    console.log "GET /dashboard"

    # read users
    users = slack.getUsers()

    if users.length is 0
      res.render('pages/dashboard')

    userIds = users.map (user) ->
      return user.id

    # read users status
    mongo.getAllUserFeedback(userIds).then (slimUsers) =>

      filteredStatuses = []

      if slimUsers.length
        slimUsers.forEach (u) ->
          if u.feedback?
            filteredStatuses[u.id]              = u.feedback
            filteredStatuses[u.id].date         = new Date u.feedback.timestamp
            filteredStatuses[u.id].statusString = OskarTexts.statusText[u.feedback.status]

        # only sort when more than one user
        if users.length > 1
          users.sort (a, b) ->
            if not filteredStatuses[a.id]?
              if not filteredStatuses[b.id]?
                a.name.toLowerCase() < b.name.toLowerCase()
              else
                1
            else if not filteredStatuses[b.id]?
              -1
            else
              filteredStatuses[a.id].date < filteredStatuses[b.id].date

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

  # message user
  app.post '/message/:userId', jsonParser, (req, res) =>
    if !req.body.message
      return res.status(400).send({ status: 'fail' })
    slack.postMessage req.params.userId, req.body.message
    res.json( { status: 'ok' } )

module.exports = routes