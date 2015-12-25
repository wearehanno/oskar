class InputHelper

  @isValidStatus: (status) ->
    numberPattern = /^[1-5]$/
    if !status.match numberPattern
      return false
    return true

  @isAskingForUserStatus: (input) ->
    userPattern = /^How is <[@|\!](\w+)>\s?\??$/i
    response = input.match userPattern
    if response?
      return response[1]
    userPattern = /^How is everyone\??$/i
    response = input.match userPattern
    if response?
      return 'channel'
    return null

  @isAskingForHelp: (input) ->
    messagePattern = /help/i
    if input.match messagePattern
      return true
    return false

  @isStatusAndFeedback: (input) ->
    messagePattern = /^(\d):\s*([\w\s\:\.\',-]+)/i
    matches = input.match messagePattern
    if matches is null
      return false
    obj =
      status: matches[1]
      message: matches[2]

module.exports = InputHelper