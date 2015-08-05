InputHelper    = require './inputHelper'
{EventEmitter} = require 'events'

class OnboardingHelper extends EventEmitter

  # mongo is passed in for some DB operations, onoboardingStatus is used for retaining status during runtime
  constructor: (mongo, userIds) ->
    @mongo = mongo
    @onboardingStatus = {}

  retainOnboardingStatusForUsers: (userIds) =>
    userIds.forEach @retainOnboardingStatusForUser

  retainOnboardingStatusForUser: (userId) =>
    @mongo.getOnboardingStatus(userId).then (res) =>
      console.log "save onboarding for user #{userId}: #{res}"
      @onboardingStatus[userId] = res

  isOnboarded: (userId) ->
    console.log "onboarding status #{userId}: " + @onboardingStatus[userId]
    @onboardingStatus[userId] is 3

  getOnboardingStatus: (userId) ->
    @onboardingStatus[userId]

  setOnboardingStatus: (userId, status) ->
    @onboardingStatus[userId] = status
    if (status is 3)
      @mongo.setOnboardingStatus userId, status

  welcome: (userId) =>

    # only welcome if status is 0
    if @getOnboardingStatus(userId) > 0
      return

    data =
      userId : userId
      type   : 'introduction'

    @setOnboardingStatus userId, 1
    @emit 'message', data

  # move on according to status and update user with message
  advance: (userId, message = null) =>
    status = @getOnboardingStatus userId

    if status is 0
      return

    data =
      userId : userId
      type   : 'firstMessage'

    if status is 1
      @setOnboardingStatus userId, 2
      @emit 'message', data
      return

    if !message || !InputHelper.isValidStatus message
      data.type = 'firstMessageFailure'
      @emit 'message', data
      return

    @setOnboardingStatus userId, 3
    @mongo.saveUserFeedback userId, message
    data.type = 'firstMessageSuccess'
    @emit 'message', data

module.exports = OnboardingHelper