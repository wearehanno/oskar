###################################################################
# Setup the tests
###################################################################
should      = require 'should'
MongoClient = require '../src/modules/mongoClient'

# Generate a new instance for each test.
mongoClient = null
connect     = null
db          = null
collection  = null

paul =
  id        : "user1",
  name      : "paul",
  real_name : "Paul Miller",
  tz        : "Europe/Amsterdam",
  tz_offet  : 7200,
  profile   :
    image_48  : "paul.jpg"

phil =
  id        : "user2",
  name      : "phil",
  real_name : "Phil Meyer",
  tz        : "Europe/Brussels",
  tz_offet  : 7200,
  profile   :
    image_48  : "phil.jpg"

users = [paul, phil]

###################################################################
# Mongo client
###################################################################

describe 'MongoClient', ->

  before ->
    # connect to local test database
    mongoClient = new MongoClient('mongodb://127.0.0.1:27017')
    connect     = mongoClient.connect()

  this.timeout(10000);

  it 'should connect to the mongo client', (done) ->
    connect.then (res) ->
      should.exist res
      done()

###################################################################
# Mongo client users
###################################################################

  describe 'MongoClientUsers', ->

    before ->
      connect.then (res) ->
        db = res
        collection = db.collection 'users'

        # empty database
        collection.remove({})

        # save user 1
        mongoClient.saveUser(users[0]).then (res) ->
          console.log 'user 1 saved'

        # save user 2
        mongoClient.saveUser(users[1]).then (res) ->
          console.log 'user 2 saved'

    it 'should not save the same user twice', (done) ->
      mongoClient.saveUser(users[0]).then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs.length.should.be.equal 1
          done()

  describe 'MongoClientStatus', ->

    it 'should save user status in user object', (done) ->
      mongoClient.saveUserStatus(users[0].id, 'away').then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->
          docs[0].should.have.property 'activity'
          done()

  describe 'MongoClientActivity', ->

    before ->
      # save user 2 to db
      mongoClient.saveUser(users[1]).then (res) ->

    it 'should return null if user has no activity', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', 'user2').then (res) ->
        should(res).be.exactly null
        done()

    it 'should return false if user doesnt exist yet', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', 'U0281LQKQ').then (res) ->
        should(res).be.exactly false
        done()

    it 'should get the latest timestamp for passed property', (done) ->
      mongoClient.getLatestUserTimestampForProperty('activity', users[0].id).then (res) ->
        collection.find({ id: users[0].id }).toArray (err, docs) ->

          # get highest timestamp
          timestamp = 0
          for activity in docs[0].activity
            timestamp = activity.timestamp if activity.timestamp > timestamp

          res.should.be.equal timestamp
          done()

  describe 'MongoClientFeedback', ->

    userId   = 'user2'
    feedback = 4
    feedbackMessage = 'This is my user feedback message'

    before ->

      mongoClient.saveUserFeedback(userId, feedback).then (res) ->
        console.log "save user feedback message for #{userId}"
        mongoClient.saveUserFeedbackMessage(userId, feedbackMessage).then (res) ->
          console.log "save user feedback for #{userId}"

    it 'should save user feedback', (done) ->

      collection.find({ id: userId }).toArray (err, docs) ->
        should(docs[0].feedback[0].status).be.equal feedback
        done()

    it 'should save a user feedback message for the last feedback entry', (done) ->

      collection.find({ id: userId }).toArray (err, docs) ->
        should(docs[0].feedback[0].message).be.equal feedbackMessage
        done()

    it 'should get the latest user feedback', (done) ->

      mongoClient.getLatestUserFeedback(userId).then (res) ->
        res.status.should.be.equal 4
        res.message.should.be.equal 'This is my user feedback message'
        done()

    it 'should return feedback for all users', (done) ->

      mongoClient.saveUserFeedback(userId, feedback).then (res) =>
        mongoClient.getAllUserFeedback(['user1', 'user2']).then (res) =>

          res[0].should.have.property 'id'
          res[1].should.have.property 'id'
          res[1].should.have.property 'feedback'
          res[1].feedback.should.have.property 'status'
          res[1].feedback.should.have.property 'timestamp'

          done()

    it 'should return how many times user has given feedback', (done) ->

      today = new Date()
      mongoClient.getUserFeedbackCount(userId, today).then (res) =>
        console.log res
        res.should.be.equal 2
        done()

  describe 'MongoClientOnboardingStatus', ->

    userId = 'user1'

    it 'should return the current onboarding status 0 if no status has been saved', (done) ->

      mongoClient.getOnboardingStatus(userId).then (res) ->
        res.should.be.equal 0
        done()

    it 'should save onboarding status', (done) ->

      mongoClient.setOnboardingStatus(userId, 1).then (res) =>
        mongoClient.getOnboardingStatus(userId).then (res) =>
          res.should.be.equal 1
          done()
