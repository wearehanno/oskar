
# Setup the tests
###################################################################
should           = require 'should'
sinon            = require 'sinon'
whenLib          = require 'when'
{EventEmitter}   = require 'events'
Oskar            = require '../src/oskar'
MongoClient      = require '../src/modules/mongoClient'
SlackClient      = require '../src/modules/slackClient'
OnboardingHelper = require '../src/helper/onboardingHelper'

###################################################################
# Helper
###################################################################

describe 'oskar', ->

  mongo            = new MongoClient()
  slack            = new SlackClient()
  onboardingHelper = new OnboardingHelper()

  # slack stubs, because these methods are unit tested elsewhere
  getUserStub              = sinon.stub slack, 'getUser'
  getUserIdsStub           = sinon.stub slack, 'getUserIds'
  isUserCommentAllowedStub = sinon.stub slack, 'isUserCommentAllowed'
  disallowUserCommentStub  = sinon.stub slack, 'disallowUserComment'
  postMessageStub          = sinon.stub slack, 'postMessage'
  postMessageToChannelSpy  = sinon.spy  slack, 'postMessageToChannel'

  # mongo stubs
  userExistsStub              = sinon.stub mongo, 'userExists'
  saveUserStub                = sinon.stub mongo, 'saveUser'
  getLatestUserTimestampStub  = sinon.stub mongo, 'getLatestUserTimestampForProperty'
  saveUserStatusStub          = sinon.stub mongo, 'saveUserStatus'
  getLatestUserFeedbackStub   = sinon.stub mongo, 'getLatestUserFeedback'
  getAllUserFeedback          = sinon.stub mongo, 'getAllUserFeedback'
  saveUserFeedbackStub        = sinon.stub mongo, 'saveUserFeedback'
  saveUserFeedbackMessageStub = sinon.stub mongo, 'saveUserFeedbackMessage'
  getUserFeedbackCountStub    = sinon.stub mongo, 'getUserFeedbackCount'

  # onboarding stubs
  isOnboardedStub                   = sinon.stub onboardingHelper, 'isOnboarded'
  welcomeStub                       = sinon.stub onboardingHelper, 'welcome'
  advanceStub                       = sinon.stub onboardingHelper, 'advance'
  retainOnboardingStatusForUsersSpy = sinon.spy onboardingHelper, 'retainOnboardingStatusForUsers'

  # stub promises
  userExistsStub.returns(whenLib false)
  saveUserStub.returns(whenLib false)
  getLatestUserTimestampStub.returns(whenLib false)
  isOnboardedStub.returns(true)

  # Oskar spy
  requestUserFeedbackStub = sinon.stub Oskar.prototype, 'requestUserFeedback'
  presenceHandlerSpy      = sinon.spy Oskar.prototype, 'presenceHandler'

  oskar              = new Oskar(mongo, slack, onboardingHelper)
  composeMessageStub = null

  # timestamps
  today = Date.now()
  yesterday = today - (3600 * 1000 * 21)

  ###################################################################
  # HelperMethods
  ###################################################################

  describe 'HelperMethods', ->

    it 'should post a message to slack', ->

      userId = 'user1'
      messageType = 'alreadySubmitted'

      oskar.composeMessage userId, messageType

      postMessageStub.called.should.be.equal true
      postMessageStub.args[0][0].should.be.equal userId

    it 'should send presence events when checkForUserStatus is called', ->

      targetUserIds = [2, 3]
      getUserIdsStub.returns(targetUserIds)

      oskar.checkForUserStatus(slack)
      presenceHandlerSpy.callCount.should.be.equal 2

  ###################################################################
  # Presence handler
  ###################################################################

  describe 'presenceHandler', ->

    before ->
      presenceHandlerSpy.restore()
      requestUserFeedbackStub.restore()
      disallowUserCommentStub.reset()

    it 'should save a non-existing user in mongo', (done) ->
      data =
        userId: 'user1'

      oskar.presenceHandler data
      setTimeout ->
        saveUserStub.called.should.be.equal true
        done()
      , 100

    it 'should return false if user is disabled', ->
      data =
        userId: 'user1'

      getUserStub.returns null

      res = oskar.presenceHandler data
      res.should.be.equal false

    it 'should disallow user comments when triggered', ->
      userObj =
        userId: 'user1'

      data =
        userId: 'user1'
        status: 'triggered'

      getUserStub.returns(data)
      oskar.presenceHandler data
      disallowUserCommentStub.called.should.be.equal true

    after ->
      disallowUserCommentStub.reset()


    ###################################################################
    # Presence handler > requestFeedback
    ###################################################################

    describe 'requestFeedback', ->

      before ->
        composeMessageStub = sinon.stub oskar, 'composeMessage'
        getUserFeedbackCountStub.returns(whenLib 0)

      beforeEach ->
        composeMessageStub.reset()

      data =
        userId: 'user1'
        status: 'active'

      it 'should request feedback from an existing user if timestamp expired', (done) ->

        userObj =
          id        : 'user1'
          presence  : 'active'
          tz_offset : 3600

        getUserStub.returns userObj

        getLatestUserTimestampStub.returns(whenLib yesterday)
        oskar.presenceHandler data

        setTimeout ->
          composeMessageStub.called.should.be.equal true
          composeMessageStub.args[0][0].should.be.equal 'user1'
          composeMessageStub.args[0][1].should.be.equal 'requestFeedback'
          done()
        , 100

      it 'should request feedback according to request count', (done) ->

        userObj =
          id       : 'user10'
          presence : 'active'

        data2 =
          userId : 'user10'
          status : 'active'

        oskar.presenceHandler data2

        setTimeout ->
          composeMessageStub.args[0][2].should.be.equal 1
          done()
        , 100

      it 'should request feedback according to request count (second time)', (done) ->

        userObj =
          id       : 'user10'
          presence : 'active'

        data2 =
          userId: 'user10'
          status: 'active'

        oskar.presenceHandler data2

        setTimeout ->
          composeMessageStub.args[0][2].should.be.equal 2
          done()
        , 100

      it 'should not request feedback from an existing user if timestamp has not expired', (done) ->

        oskar.presenceHandler data
        getLatestUserTimestampStub.returns(whenLib today)

        setTimeout ->
          composeMessageStub.called.should.be.equal false
          done()
        , 100

      it 'should request feedback from an existing user if timestamp has expired', (done) ->

        oskar.presenceHandler data
        getLatestUserTimestampStub.returns(whenLib yesterday)

        setTimeout ->
          composeMessageStub.called.should.be.equal true
          done()
        , 100

      it 'should not request feedback from an existing user if status is not active or triggered', (done) ->

        data.status = 'away'
        getLatestUserTimestampStub.returns(whenLib yesterday)

        oskar.presenceHandler data

        setTimeout ->
          composeMessageStub.called.should.be.equal false
          done()
        , 100

      it 'should not request user feedback if user isn\'t active', (done) ->

        userObj =
          userId   : 'user2'
          presence : 'away'

        getUserStub.returns userObj

        data.status = 'triggered'
        oskar.presenceHandler data
        getLatestUserTimestampStub.returns(whenLib yesterday)

        setTimeout ->
          composeMessageStub.called.should.be.equal false
          done()
        , 100

      it 'should not request user feedback if user has left feedback twice', (done) ->

        data =
          userId: 'user1'
          status: 'active'

        userObj =
          userId: 'user1'
          presence: 'active'
          tz_offset: 0

        getUserStub.returns userObj
        getLatestUserTimestampStub.returns(whenLib yesterday)
        getUserFeedbackCountStub.returns(whenLib 2)

        oskar.presenceHandler data

        setTimeout ->
          composeMessageStub.called.should.be.equal false
          done()
        , 100


  ###################################################################
  # Message handler
  ###################################################################

  describe 'messageHandler', ->

    before ->
      isUserCommentAllowedStub.withArgs('user3').returns(whenLib true)

    beforeEach ->
      composeMessageStub.reset()
      saveUserFeedbackStub.reset()

    it 'should reveal status for a user', (done) ->

      message =
        text: 'How is <@USER2>?'
        user: 'user1'

      targetUserObj =
        id   : 'USER2',
        name : 'paul'
        profile:
          first_name: 'Paul'

      res =
        status: 8
        message: 'feeling great'

      getUserStub.returns targetUserObj
      getLatestUserFeedbackStub.returns(whenLib res)

      oskar.messageHandler message
      setTimeout ->
        composeMessageStub.args[0][0].should.be.equal 'user1'
        composeMessageStub.args[0][1].should.be.equal 'revealUserStatus'
        composeMessageStub.args[0][2].status.should.be.equal res.status
        composeMessageStub.args[0][2].message.should.be.equal res.message
        done()
      , 100

    it 'should reveal status for the channel', (done) ->

      message =
        text: 'How is <@channel>?'
        user: 'user1'

      res =
        0:
          id: 'user2'
          feedback:
            status: 4
            message: 'bad mood'
        1:
          id: 'user3'
          feedback:
            status: 2
            message: 'physically down'

      targetUserIds = [2, 3]

      getUserIdsStub.returns targetUserIds
      getAllUserFeedback.returns(whenLib res)

      oskar.messageHandler message
      setTimeout ->
        composeMessageStub.args[0][1].should.be.equal 'revealChannelStatus'
        composeMessageStub.args[0][2].should.be.equal res
        done()
      , 100

    it 'should not allow feedback if already submitted', (done) ->

      message =
        text: '7'
        user: 'user1'

      getLatestUserTimestampStub.returns(whenLib today)

      oskar.messageHandler message

      setTimeout ->
        saveUserFeedbackStub.called.should.be.equal false
        composeMessageStub.called.should.be.equal true
        composeMessageStub.args[0][0].should.be.equal message.user
        composeMessageStub.args[0][1].should.be.equal 'alreadySubmitted'
        done()
      , 100

    it 'should not allow invalid feedback', (done) ->

      message =
        text: 'something'
        user: 'user1'

      getLatestUserTimestampStub.returns(whenLib yesterday)

      oskar.messageHandler message

      setTimeout ->
        composeMessageStub.called.should.be.equal true
        composeMessageStub.args[0][0].should.be.equal message.user
        composeMessageStub.args[0][1].should.be.equal 'invalidInput'
        done()
      , 100

    it 'should ask user for feedback message if feedback low', (done) ->

      message =
        text: '2'
        user: 'user1'

      getLatestUserTimestampStub.returns(whenLib yesterday)

      oskar.messageHandler message

      setTimeout ->
        composeMessageStub.called.should.be.equal true
        composeMessageStub.args[0][0].should.be.equal message.user
        composeMessageStub.args[0][1].should.be.equal 'lowFeedback'
        done()
      , 100

    it 'should ask user for feedback message if feedback is high', (done) ->

      message =
        text: '4'
        user: 'user1'

      getLatestUserTimestampStub.returns(whenLib yesterday)

      oskar.messageHandler message

      setTimeout ->
        composeMessageStub.called.should.be.equal true
        composeMessageStub.args[0][0].should.be.equal message.user
        composeMessageStub.args[0][1].should.be.equal 'highFeedback'
        done()
      , 100

    it 'should thank the user for feedback message if feedback allowed, save feedback to mongo and disallow comment', (done) ->

      message =
        text: 'not feeling so well'
        user: 'user3'

      oskar.messageHandler message

      setTimeout ->
        composeMessageStub.called.should.be.equal true
        composeMessageStub.args[0][0].should.be.equal message.user
        composeMessageStub.args[0][1].should.be.equal 'feedbackMessageReceived'
        saveUserFeedbackMessageStub.called.should.be.equal true
        disallowUserCommentStub.called.should.be.equal true
        done()
      , 100

    it 'should return a faq message when user asks for help', (done) ->

      message =
        text: 'i need some help'
        user: 'user1'

      oskar.messageHandler message

      setTimeout ->
        composeMessageStub.called.should.be.equal true
        composeMessageStub.args[0][0].should.be.equal message.user
        composeMessageStub.args[0][1].should.be.equal 'faq'
        done()
      , 100


    it 'should trigger a presence event for each user', ->

      spy = sinon.spy()

      slack.on 'presence', spy
      getUserIdsStub.returns ['testuser1', 'testuser2']

      oskar.checkForUserStatus(slack)

      spy.callCount.should.be.equal 2
      spy.firstCall.args[0].userId.should.be.equal 'testuser1'
      spy.firstCall.args[0].status.should.be.equal 'triggered'
      spy.secondCall.args[0].userId.should.be.equal 'testuser2'
      spy.secondCall.args[0].status.should.be.equal 'triggered'

    it 'should send a user\'s feedback to everyone alongside the status', (done) ->

      broadcastUserStatusSpy = sinon.spy Oskar.prototype, 'broadcastUserStatus'

      message =
        text: 'not feeling so great'
        user: 'user1'

      getLatestUserFeedbackStub.returns(whenLib { status: 5 })
      oskar.handleFeedbackMessage message

      setTimeout ->
        broadcastUserStatusSpy.args[0][0].should.be.equal message.user
        broadcastUserStatusSpy.args[0][1].should.be.type 'number'
        broadcastUserStatusSpy.args[0][2].should.be.equal message.text
        broadcastUserStatusSpy.called.should.be.equal true
        done()
      , 100

    it 'should send a message to the whole team excluding user that submitted feedback', ->

      team = ['teammate1', 'teammate2', 'teammate3', 'user1']

      getUserIdsStub.returns team

      oskar.broadcastUserStatus('user1', 5, 'feeling awesome')

      # make sure message is going to all users
      composeMessageStub.args[0][0].should.be.equal team[0]
      composeMessageStub.args[1][0].should.be.equal team[1]
      composeMessageStub.args[2][0].should.be.equal team[2]

      composeMessageStub.args[0][1].should.be.equal 'newUserFeedbackToUser'
      composeMessageStub.args[0][2].should.have.property 'first_name'
      composeMessageStub.args[0][2].should.have.property 'status'
      composeMessageStub.args[0][2].should.have.property 'feedback'

  ###################################################################
  # Onboarding handler
  ###################################################################

  describe 'Onboarding', ->

    this.timeout 10000

    users = ['user1', 'user2', 'user3']

    beforeEach ->
      composeMessageStub.reset()

    it 'should trigger composeMessage when onboarding helper is called', ->
      message =
        userId : 'user1'
        type   : 'introduction'

      oskar.onboardingHandler message
      composeMessageStub.called.should.be.equal true

    it 'should call welcome message of onboarding helper when user is not onboarded', ->
      data =
        userId: 'user2'

      userObj =
        userId   : 'user2'
        presence : 'active'

      getUserStub.returns userObj

      isOnboardedStub.returns false
      oskar.presenceHandler data
      welcomeStub.called.should.be.equal true

    it 'should call advance message of onboarding helper when user is not onboarded', ->
      data =
        userId  : 'user2'
        message : 'text'

      isOnboardedStub.returns false
      oskar.messageHandler data
      advanceStub.called.should.be.equal true

    it 'should call composeMessage when onboardingHandler is called', ->
      message =
        userId : 'user1'
        type   : 'introduction'

      oskar.onboardingHandler message
      composeMessageStub.called.should.be.equal true
      composeMessageStub.args[0][0].should.be.equal message.userId
      composeMessageStub.args[0][1].should.be.equal message.type

  ###################################################################
  # Compose message (has to be last to restore composeMessageStub)
  ###################################################################
  describe 'ComposeMessage', ->

    beforeEach ->
      postMessageStub.reset()

    it 'should compose a message', ->

      postMessageStub.reset()
      composeMessageStub.restore()

      userObj =
        userId   : 'user2'
        presence : 'active'
        profile  :
          first_name: 'Phil'

      getUserStub.returns userObj

      oskar.composeMessage 'user1', 'requestFeedback', 0
      postMessageStub.args[0][0].should.be.equal 'user1'
      postMessageStub.args[0][1].should.be.type 'string'

    it 'should send the feedback messages to a channel if a channel has been defined', ->

      userStatus =
        first_name : 'Marcel'
        status     : '4'
        feedback   : 'all good'

      process.env.CHANNEL_ID = 'channelOne'
      oskar.composeMessage 'user1', 'newUserFeedbackToChannel', userStatus

      postMessageToChannelSpy.args[0][0].should.be.equal process.env.CHANNEL_ID
      postMessageToChannelSpy.args[0][1].should.be.type 'string'

    ###################################################################
    # The following can be used to verify the responses (just remove the comment from the log function)
    ###################################################################

    it 'should compose a request feedback message', ->

      postMessageStub.reset()
      oskar.composeMessage 'user1', 'requestFeedback', 0
      # console.log postMessageStub.args

    it 'should compose a new user feedback message', ->

      obj =
        first_name : 'Marcel'
        status     : '3'
        feedback   : 'alright'

      postMessageStub.reset()
      oskar.composeMessage 'user1', 'newUserFeedback', obj
      # console.log postMessageStub.args

    it 'should compose a channel status message', ->

      users = [
        {id: 'user1',
        feedback:
          status: 5
          message: 'great'
        },

        {id: 'user2',
        feedback:
          status: 4
          message: 'not so good'
        }
      ]

      oskar.composeMessage 'user1', 'revealChannelStatus', users
      # console.log postMessageStub.args

    it 'should compose a request user status message with an error', ->

      obj =
        user:
          profile:
            first_name: 'Paul'

      postMessageStub.reset()
      oskar.composeMessage 'user1', 'revealUserStatus', obj
      # console.log postMessageStub.args

    it 'should compose a request user status message successfully', ->

      obj =
        user:
          profile:
            first_name: 'Paul'
        status: 4
        message: 'phenomenal'

      postMessageStub.reset()
      oskar.composeMessage 'user1', 'revealUserStatus', obj
      # console.log postMessageStub.args

    it 'should compose a faq message', ->

      oskar.composeMessage 'user1', 'faq'
      # console.log postMessageStub.args

    it 'should compose an invalidInput message', ->

      oskar.composeMessage 'user1', 'invalidInput'
      # console.log postMessageStub.args
