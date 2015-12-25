###################################################################
# Setup the tests
###################################################################
should = require 'should'
sinon = require 'sinon'
whenLib = require 'when'

MongoClient = require '../src/modules/mongoClient'
OnboardingHelper = require '../src/helper/onboardingHelper'

###################################################################
# Onboarding Helper
###################################################################

mongo = new MongoClient()
mongoSetOnboardingStatusStub = sinon.stub mongo, 'setOnboardingStatus'
mongoGetOnboardingStatusStub = sinon.stub mongo, 'getOnboardingStatus'
mongoSaveUserFeedbackStub = sinon.stub mongo, 'saveUserFeedback'

# return a different onboarding status for each user
mongoGetOnboardingStatusStub.withArgs('user1').returns(whenLib 1)
mongoGetOnboardingStatusStub.withArgs('user2').returns(whenLib 0)
mongoGetOnboardingStatusStub.withArgs('user3').returns(whenLib 3)

userIds = ['user1', 'user2', 'user3']

onboardingHelper = new OnboardingHelper(mongo, userIds)
onboardingHelper.loadOnboardingStatusForUsers(userIds)

describe 'OnboardingHelper', ->

  describe 'OnboardingStatus', ->

    it 'should return false when the user has not been onboarded', ->
      userId = 'user1'
      isOnboarded = onboardingHelper.isOnboarded(userId)
      isOnboarded.should.be.equal(false)

    it 'should return true when the user has been onboarded', ->
      userId = 'user3'
      isOnboarded = onboardingHelper.isOnboarded(userId)
      isOnboarded.should.be.equal(true)

  describe 'OnboardingEvents', ->

    it 'should emit an introduction event when welcome is called and user onboarding status is 0', ->
      spy = sinon.spy()
      onboardingHelper.on 'message', spy
      onboardingHelper.welcome('user2')
      spy.called.should.be.equal true
      spy.args[0][0].type.should.be.equal 'introduction'

    it 'should emit a firstMessage event when advance is called and user onboarding status is 1', ->
      spy = sinon.spy()
      onboardingHelper.on 'message', spy
      onboardingHelper.setOnboardingStatus('user1', 1)
      onboardingHelper.advance('user1')
      spy.called.should.be.equal true
      spy.args[0][0].type.should.be.equal 'firstMessage'

    it 'should emit a firstMessageFailure event when advance is called, user onboarding status is 2 and message is not valid', ->
      spy = sinon.spy()
      onboardingHelper.on 'message', spy
      onboardingHelper.setOnboardingStatus('user1', 2)
      onboardingHelper.advance('user1', null)
      spy.called.should.be.equal true
      spy.args[0][0].type.should.be.equal 'firstMessageFailure'

    it 'should emit a firstMessageSuccess event when advance is called, user onboarding status is 2 and message is valid', ->
      spy = sinon.spy()
      onboardingHelper.on 'message', spy
      onboardingHelper.setOnboardingStatus('user1', 2)
      onboardingHelper.advance('user1', '1')
      spy.args[0][0].type.should.be.equal 'firstMessageSuccess'
      spy.called.should.be.equal true

  describe 'OnboardingDatabase', ->

    before ->
      mongoSetOnboardingStatusStub.reset()
      onboardingHelper.advance('user1', '4')

    it 'should save status in mongo when onboarding completed', ->
      mongoSetOnboardingStatusStub.called.should.be.equal true
      mongoSetOnboardingStatusStub.args[0][0].should.be.equal 'user1'
      mongoSetOnboardingStatusStub.args[0][1].should.be.equal 3