###################################################################
# Setup the tests
###################################################################
should      = require 'should'
InputHelper = require '../src/helper/inputHelper'

###################################################################
# Helper
###################################################################

describe 'InputHelper', ->

  # is valid status
  it 'should return true if status string is a valid number', ->
    response = InputHelper.isValidStatus '3'
    response.should.be.equal true

  # is asking for user status
  it 'should return the username if using user status command', ->
    text = 'How is <@user1>?'
    response = InputHelper.isAskingForUserStatus text
    response.should.be.equal 'user1'

  # is asking for user status (channel)
  it 'should return "channel" if user is asking for channel status', ->
    text = 'How is <!channel>?'
    response = InputHelper.isAskingForUserStatus(text)
    should(response).be.equal 'channel'

  # is asking for help
  it 'should return true if user is asking for help', ->
    text = 'I need some help'
    response = InputHelper.isAskingForHelp text
    should(response).be.equal true

  # is status and feedback
  it 'should return the status number and feedback message', ->
    text = '3: feeling average :confused:'
    response = InputHelper.isStatusAndFeedback text
    response.status.should.be.equal '3'
    response.message.should.be.equal 'feeling average :confused:'