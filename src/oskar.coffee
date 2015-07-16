express          = require 'express'
MongoClient      = require './modules/mongoClient'
SlackClient      = require './modules/slackClient'
routes           = require './modules/routes'
TimeHelper       = require './helper/timeHelper'
InputHelper      = require './helper/inputHelper'
OnboardingHelper = require './helper/onboardingHelper'
OskarTexts       = require './content/oskarTexts'

class Oskar

  constructor: (mongo, slack, onboardingHelper) ->

    # set up app, mongo and slack
    @app = express()
    @app.set 'view engine', 'ejs'
    @app.set 'views', 'src/views/'
    @app.use '/public', express.static(__dirname + '/public')

    @mongo = mongo || new MongoClient()
    @mongo.connect()

    @slack = slack || new SlackClient()
    @slack.connect().then () =>
      @onboardingHelper.retainOnboardingStatusForUsers @slack.getUserIds()

    @onboardingHelper = onboardingHelper || new OnboardingHelper @mongo

    @setupRoutes()

    # dev environment shouldnt listen to slack events or run the interval
    if process.env.NODE_ENV is 'development'
      return

    @setupEvents()

    # check for user's status every hour
    setInterval =>
      @checkForUserStatus (@slack)
    , 3600 * 1000

  setupEvents: () =>
    @slack.on 'presence', @presenceHandler
    @slack.on 'message', @messageHandler
    @onboardingHelper.on 'message', @onboardingHandler

  setupRoutes: () ->

    routes(@app, @mongo, @slack)

    @app.set 'port', process.env.PORT || 5000
    @app.listen @app.get('port'), ->
      console.log "Node app is running on port 5000"

  presenceHandler: (data) =>

    # return if user has been disabled
    user = @slack.getUser data.userId
    if user is null
      return false

    # every hour, disable possibility to comment
    if data.status is 'triggered'
      @slack.disallowUserComment data.userId

    # if presence is not active, return
    user = @slack.getUser data.userId
    if (user and user.presence isnt 'active')
      return

    # if user is not onboarded, do so
    if !@onboardingHelper.isOnboarded(data.userId)
      return @onboardingHelper.welcome(data.userId)

    # if a user exists, create, otherwise go ahead without
    @mongo.userExists(data.userId).then (res) =>
      if !res
        @mongo.saveUser(user).then (res) =>
          @requestUserFeedback data.userId, data.status
      else
        @requestUserFeedback data.userId, data.status

  messageHandler: (message) =>

    # if user is not onboarded, run until onboarded
    if !@onboardingHelper.isOnboarded(message.user)
      return @onboardingHelper.advance(message.user, message.text)

    # if user is asking for feedback of user with ID
    if userId = InputHelper.isAskingForUserStatus(message.text)
      return @revealStatus userId, message

    # if comment is allowed, save in DB
    if @slack.isUserCommentAllowed message.user
      return @handleFeedbackMessage message

    # if user is asking for help, send a link to the FAQ
    if InputHelper.isAskingForHelp(message.text)
      return @composeMessage message.user, 'faq'

    # if feedback is long enough ago, evaluate
    @mongo.getLatestUserTimestampForProperty('feedback', message.user).then (timestamp) =>
      @evaluateFeedback message, timestamp

  # is called from onboarding helper to compose messages
  onboardingHandler: (message) =>
    @composeMessage(message.userId, message.type)

  requestUserFeedback: (userId, status) ->

    @mongo.saveUserStatus userId, status

    # if user switched to anything but active or triggered, skip
    if status != 'active' && status != 'triggered'
      return

    # if it's weekend or between 0-8 at night, skip
    user = @slack.getUser userId
    date = TimeHelper.getLocalDate(null, user.tz_offset / 3600)
    if (TimeHelper.isWeekend() || TimeHelper.isDateInsideInterval 0, 8, date)
      return

    @mongo.getLatestUserTimestampForProperty('feedback', userId).then (timestamp) =>

      # if user doesnt exist, skip
      if timestamp is false
        return

      # if timestamp has expired and user has not already been asked two times, ask for status
      today = new Date()
      @mongo.getUserFeedbackCount(userId, today).then (count) =>

        if (count < 2 && TimeHelper.hasTimestampExpired 6, timestamp)
          requestsCount = @slack.getfeedbackRequestsCount(userId)
          @slack.setfeedbackRequestsCount(userId, requestsCount + 1)
          @composeMessage userId, 'requestFeedback', requestsCount

  evaluateFeedback: (message, latestFeedbackTimestamp, firstFeedback = false) ->

    # if user has already submitted feedback in the last x hours, reject
    if (latestFeedbackTimestamp && !TimeHelper.hasTimestampExpired 4, latestFeedbackTimestamp)
      return @composeMessage message.user, 'alreadySubmitted'

    # if user didn't send valid feedback
    if !InputHelper.isValidStatus message.text
      return @composeMessage message.user, 'invalidInput'

    # if feedback valid, save and set count to 0
    @mongo.saveUserFeedback message.user, message.text
    @slack.setfeedbackRequestsCount(message.user, 0)

    @slack.allowUserComment message.user

    # get user feedback
    if (parseInt(message.text) < 3)
      return @composeMessage message.user, 'lowFeedback'

    if (parseInt(message.text) is 3)
      return @composeMessage message.user, 'averageFeedback'

    if (parseInt(message.text) > 3)
      return @composeMessage message.user, 'highFeedback'

    @composeMessage message.user, 'feedbackReceived'

  revealStatus: (userId, message) =>

    # distinguish between channel and user
    if userId is 'channel'
      @revealStatusForChannel(message.user)
    else
      @revealStatusForUser(message.user, userId)

  revealStatusForChannel: (userId) =>
    userIds = @slack.getUserIds()
    @mongo.getAllUserFeedback(userIds).then (res) =>
      @composeMessage userId, 'revealChannelStatus', res

  revealStatusForUser: (userId, targetUserId) =>
    userObj = @slack.getUser targetUserId

    # return if user has been disabled or is not available
    if userObj is null
      return

    @mongo.getLatestUserFeedback(targetUserId).then (res) =>
      if res is null
        res = {}
      res.user = userObj
      @composeMessage userId, 'revealUserStatus', res

  handleFeedbackMessage: (message) =>

    # after receiving it, save and disallow comments
    @slack.disallowUserComment message.user
    @mongo.saveUserFeedbackMessage message.user, message.text
    @composeMessage message.user, 'feedbackMessageReceived'

    # send feedback to everyone
    @mongo.getLatestUserFeedback(message.user).then (res) =>
      @broadcastUserStatus message.user, res.status, message.text

  broadcastUserStatus: (userId, status, feedback) ->

    user = @slack.getUser userId

    # compose user details
    userStatus =
      first_name : user.profile.first_name
      status     : status
      feedback   : feedback

    # send update to all users
    userIds = @slack.getUserIds()

    userIds.forEach (user) =>
      @composeMessage user, 'newUserFeedback', userStatus

  composeMessage: (userId, messageType, obj) ->

    # random number to pick varying messages from content file
    random =  Math.floor(Math.random() * (4 - 1)) + 1

    # request feedback
    if messageType is 'requestFeedback'
      userObj = @slack.getUser userId
      if obj < 1
        statusMsg = OskarTexts.requestFeedback.random[random-1].format userObj.profile.first_name
        statusMsg += OskarTexts.requestFeedback.selection
      else
        statusMsg = OskarTexts.requestFeedback.options[obj-1]

    # channel info
    else if messageType is 'revealChannelStatus'
      statusMsg = ""
      obj.forEach (user) =>
        userObj = @slack.getUser user.id
        statusMsg += OskarTexts.revealChannelStatus.status.format userObj.profile.first_name, user.feedback.status
        if user.feedback.message
          statusMsg += OskarTexts.revealChannelStatus.message.format user.feedback.message
        statusMsg += "\r\n"

    # user info
    else if messageType is 'revealUserStatus'
      if !obj.status
        statusMsg = OskarTexts.revealUserStatus.error.format obj.user.profile.first_name
      else
        statusMsg = OskarTexts.revealUserStatus.status.format obj.user.profile.first_name, obj.status
        if obj.message
          statusMsg += OskarTexts.revealUserStatus.message.format obj.message

    else if messageType is 'newUserFeedback'
      statusMsg = OskarTexts.newUserFeedback.format obj.first_name, obj.status, obj.feedback

    # faq
    else if messageType is 'faq'
      statusMsg = OskarTexts.faq

    # everything else
    else statusMsg = OskarTexts[messageType]

    if userId && statusMsg
      @slack.postMessage(userId, statusMsg)

  # interval to request feedback every hour
  checkForUserStatus: (slack) =>
    userIds = slack.getUserIds()
    userIds.forEach (userId) ->
      data =
        userId: userId
        status: 'triggered'
      slack.emit 'presence', data

module.exports = Oskar