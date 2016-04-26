
# Setup the tests
###################################################################
should           = require 'should'
request          = require 'supertest'
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

  mongo            = new MongoClient('mongodb://127.0.0.1:27017/users')
  slack            = new SlackClient()
  onboardingHelper = new OnboardingHelper()

  # slack stubs, because these methods are unit tested elsewhere
  getUserStub              = sinon.stub slack, 'getUser'
  getUserIdsStub           = sinon.stub slack, 'getUserIds'
  isUserFeedbackMessageAllowedStub = sinon.stub slack, 'isUserFeedbackMessageAllowed'
  disallowUserFeedbackMessageStub  = sinon.stub slack, 'disallowUserFeedbackMessage'

  # mongo stubs
  userExistsStub              = sinon.stub mongo, 'userExists'
  saveUserStub                = sinon.stub mongo, 'saveUser'
  getLatestUserTimestampStub  = sinon.stub mongo, 'getLatestUserTimestampForProperty'
  getLatestUserFeedbackStub   = sinon.stub mongo, 'getLatestUserFeedback'
  saveUserFeedbackStub        = sinon.stub mongo, 'saveUserFeedback'
  saveUserFeedbackMessageStub = sinon.stub mongo, 'saveUserFeedbackMessage'
  getUserFeedbackCountStub    = sinon.stub mongo, 'getUserFeedbackCount'

  # onboarding stubs
  isOnboardedStub                   = sinon.stub onboardingHelper, 'isOnboarded'
  welcomeStub                       = sinon.stub onboardingHelper, 'welcome'
  advanceStub                       = sinon.stub onboardingHelper, 'advance'

  # stub promises
  userExistsStub.returns(whenLib false)
  saveUserStub.returns(whenLib false)

  # define stub promises replies
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

    beforeEach ->
      presenceHandlerSpy.reset()

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
      disallowUserFeedbackMessageStub.reset()

    it 'should save a non-existing user in mongo', (done) ->
      data =
        userId: 'user1'

      oskar.presenceHandler data
      setTimeout ->
        saveUserStub.called.should.be.equal true
        done()
      , 1

    ###################################################################
    # Presence handler > requestFeedback
    ###################################################################

    describe 'requestFeedback', ->

      before ->
        composeMessageStub = sinon.stub oskar, 'composeMessage'
        getUserFeedbackCountStub.returns(whenLib 0)
        presenceHandlerSpy.restore()

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
          composeMessageStub.args[0][1].should.be.equal 'requestFeedback'
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

  ###################################################################
  # Message handler
  ###################################################################

  describe 'messageHandler', ->

    before ->
      isUserFeedbackMessageAllowedStub.withArgs('user3').returns(whenLib true)
      res =
        status: 8
        message: 'feeling great'
      getLatestUserFeedbackStub.returns(whenLib res)

    beforeEach ->
      composeMessageStub.reset()
      saveUserFeedbackStub.reset()

    it 'should not allow feedback if already submitted', (done) ->
      message =
        text: '7'
        user: 'user1'
      getLatestUserTimestampStub.returns(whenLib today)
      oskar.messageHandler message
      setTimeout ->
        saveUserFeedbackStub.called.should.be.equal false
        composeMessageStub.args[0][1].should.be.equal 'alreadySubmitted'
        done()
      , 1

    it 'should ask user for feedback message if feedback low', (done) ->
      message =
        text: '2'
        user: 'user1'

      getLatestUserTimestampStub.returns(whenLib yesterday)
      oskar.messageHandler message
      setTimeout ->
        composeMessageStub.args[0][1].should.be.equal 'lowFeedback'
        done()
      , 1

    it 'should thank the user for feedback message, save feedback to mongo and disallow comment', (done) ->
      message =
        text: 'not feeling so well'
        user: 'user3'

      oskar.messageHandler message
      setTimeout ->
        composeMessageStub.args[0][1].should.be.equal 'feedbackMessageReceived'
        saveUserFeedbackMessageStub.called.should.be.equal true
        disallowUserFeedbackMessageStub.called.should.be.equal true
        done()
      , 1

    it 'should allow user to send status and feedback message in one', (done) ->
      message =
        text: '3: not feeling so well'
        user: 'user4'
      oskar.messageHandler message
      setTimeout ->
        composeMessageStub.args[0][1].should.be.equal 'feedbackMessageReceived'
        done()
      , 1

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
        done()
      , 1

    it 'should send the channels status to the user that requested it', (done) ->

      message =
        text: 'not feeling so great'
        user: 'user1'

      oskar.revealStatus 'channel', message
      setTimeout ->
        composeMessageStub.args[0][1].should.be.equal 'revealChannelStatus'
        done()
      , 1

  ###################################################################
  # Onboarding handler
  ###################################################################

  describe 'Onboarding', ->

    it 'should call welcome message of onboarding helper when user is not onboarded', (done) ->
      data =
        userId: 'user2'

      userObj =
        userId   : 'user2'
        presence : 'active'

      getUserStub.returns userObj

      isOnboardedStub.returns false
      oskar.presenceHandler data

      setTimeout ->
        welcomeStub.called.should.be.equal true
        done()
      , 1

    it 'should call advance message of onboarding helper when user is not onboarded', ->
      data =
        userId  : 'user2'
        message : 'text'

      isOnboardedStub.returns false
      oskar.messageHandler data
      advanceStub.called.should.be.equal true