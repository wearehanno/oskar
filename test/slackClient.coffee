###################################################################
# Setup the tests
###################################################################
should      = require 'should'
sinon       = require 'sinon'
config      = require 'config'
SlackClient = require '../src/modules/slackClient'
slackClient = null
connect     = null

###################################################################
# Slack client
###################################################################

describe 'SlackClient', ->

  before ->
    slackClient = new SlackClient(null, 'xoxb-7369872208-yv3ZYe8kqwBDn8ugClt8wchL')
    connect     = slackClient.connect()

  this.timeout 10000

  it 'should connect to the slack client', (done) ->
    connect.then (res) ->
      res.should.have.property 'autoReconnect'
      res.should.have.property 'autoMark'
      done()

###################################################################
# Slack client users
###################################################################

  describe 'SlackClientUsers', ->

    users            = null
    userIds          = null
    disabledUsers    = null
    disabledChannels = null

    before ->
      connect.then ->
        users            = slackClient.getUsers()
        userIds          = slackClient.getUserIds()
        disabledUsers    = config.get 'slack.disabledUsers'
        disabledChannels = config.get 'slack.disabledChannels'

    describe 'PublicMethods', ->

      it 'should return a list of users', ->
        users.length.should.be.greaterThan 0

      it 'should get the IDs of all users', ->
        userIds[0].should.match(/^U\w+$/)

      it 'should not contain IDs of disabled users', ->
        if disabledUsers.length
          disabledUsers.forEach (userId) ->
            users.indexOf(userId).should.be.equal(-1)

      it 'should get a user', ->
        user = slackClient.getUser userIds[0]
        user.name.should.be.type 'string'
        user.profile.first_name.should.be.type 'string'
        user.profile.last_name.should.be.type 'string'

      it 'should return null if user is disabled', ->
        if disabledUsers.length
          user = slackClient.getUser(disabledUsers[0])
          should(user).be.equal(null)

      it 'should allow a user comment for a user', ->
        userId = userIds[0]
        slackClient.allowUserComment(userId)
        user = slackClient.getUser(userId)
        user.allowComment.should.be.equal(true)

      it 'should disallow a user comment for a user', ->
        userId = userIds[0]
        slackClient.disallowUserComment(userId)
        user = slackClient.getUser(userId)
        user.allowComment.should.be.equal(false)

      it 'should return false if user comment is not yet allowed', ->
        userId = userIds[0]
        allowed = slackClient.isUserCommentAllowed(userId)
        allowed.should.be.equal(false)

      it 'should return true if user comment is allowed after setting it', ->
        userId = userIds[0]
        slackClient.allowUserComment(userId)
        allowed = slackClient.isUserCommentAllowed(userId)
        allowed.should.be.equal(true)

      it 'should return the number of times oskar has asked this user for help', ->
        userId = userIds[0]
        number = slackClient.getfeedbackRequestsCount(userId)
        number.should.be.equal(0)

      it 'should set the number of times oskar has asked this user for help', ->
        userId = userIds[0]
        slackClient.setfeedbackRequestsCount(userId, 1)
        number = slackClient.getfeedbackRequestsCount(userId)
        number.should.be.equal(1)

      it 'should post a message to a channel', (done) ->
        slackClient.postMessageToChannel 'C07AWEMBP', 'test', (args) ->
          should(args.ok).be.equal true
          done()

    describe 'EventHandlers', ->

      it 'should send a presence event when user changes presence', ->

        data =
          id: userIds[0]

        spy = sinon.spy()
        slackClient.on('presence', spy);
        slackClient.presenceChangeHandler data, 'away'

        spy.called.should.be.equal(true);
        spy.args[0][0].userId.should.be.equal(userIds[0])
        spy.args[0][0].status.should.be.equal('away')

      it 'should set the user status when user changes presence', ->

        data =
          id: userIds[0]

        slackClient.presenceChangeHandler data, 'away'

        user = slackClient.getUser data.id
        user.presence.should.be.equal 'away'

        slackClient.presenceChangeHandler data, 'active'

        user = slackClient.getUser data.id
        user.presence.should.be.equal 'active'

      it 'should return false when message handler is called with no user', ->
        message =
          user: undefined

        response = slackClient.messageHandler(message)
        response.should.be.equal(false)

      it 'should return false when message handler is called for a disabled channel', ->

        if disabledChannels.length
          message =
            user: 'user1'
            channel: disabledChannels[0]

          response = slackClient.messageHandler(message)
          response.should.be.equal(false)

      it 'should return false when message handler if user is slackbot', ->

        message =
          userId: 'USLACKBOT'

        response = slackClient.messageHandler(message)
        response.should.be.equal(false)

      it 'should return false when message handler is called with a disabled channel', ->

        if disabledChannels.length
          message =
            user: 'user1'
            channel: disabledChannels[0]

        response = slackClient.messageHandler(message)
        response.should.be.equal(false)

      it 'should trigger a message event when message handler is called with a user and valid text is passed', ->

        message =
          user: userIds[0]
          text: 'How is <@#{userIds[1]}>?'

        spy = sinon.spy()
        slackClient.on 'message', spy

        slackClient.messageHandler message
        spy.called.should.be.equal true

        spy.args[0][0].type.should.be.equal 'input'
        spy.args[0][0].user.should.be.equal userIds[0]
        spy.args[0][0].text.should.be.equal 'How is <@#{userIds[1]}>?'