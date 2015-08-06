###################################################################
# Setup the tests
###################################################################
should      = require 'should'
InputHelper = require '../src/helper/inputHelper'

###################################################################
# Helper
###################################################################

describe 'InputHelper', ->

  it 'should return false if status string is not a number', ->
    response = InputHelper.isValidStatus 'a random string'
    response.should.be.equal false

  it 'should return true if status string is a valid number', ->
    response = InputHelper.isValidStatus '3'
    response.should.be.equal true

  it 'should return the username if using user status command', ->
    text = 'How is <@user1>?'
    response = InputHelper.isAskingForUserStatus text
    response.should.be.equal 'user1'

    text = 'How is <@user2> ?'
    response = InputHelper.isAskingForUserStatus text
    response.should.be.equal 'user2'

  it 'should return false if the user status command isnt recognized', ->
    text = 'How do you think is user1'
    response = InputHelper.isAskingForUserStatus text
    should(response).be.equal null

  it 'should return "channel" if user is asking for channel status', ->
    text = 'How is <!channel>?'
    response = InputHelper.isAskingForUserStatus(text)
    should(response).be.equal 'channel'

  it 'should return true if user is asking for help', ->
    text = 'I need some help'
    response = InputHelper.isAskingForHelp text
    should(response).be.equal true

  it 'should return the status number and feedback message', ->
    text = '3: feeling average :confused:'
    response = InputHelper.isStatusAndFeedback text
    response.status.should.be.equal '3'
    response.message.should.be.equal 'feeling average :confused:'

  it 'should return false if not number and feedback message', ->
    text = '4'
    response = InputHelper.isStatusAndFeedback text
    response.should.be.equal false
    text = 'something'
    response = InputHelper.isStatusAndFeedback text
    response.should.be.equal false