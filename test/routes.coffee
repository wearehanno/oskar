###################################################################
# Setup the tests
###################################################################
request          = require 'supertest'
should           = require 'should'
sinon            = require 'sinon'
express          = require 'express'
routes           = require '../src/modules/routes'
MongoClient      = require '../src/modules/mongoClient'
SlackClient      = require '../src/modules/slackClient'

###################################################################
# Helper
###################################################################

describe 'Routes', ->

  @mongo = null
  @slack = null
  @app = null
  postMessageStub = null

  before ->
    @mongo            = new MongoClient()
    @slack            = new SlackClient()
    postMessageStub   = sinon.stub @slack, 'postMessage'

    @app = express()
    @app.set 'view engine', 'ejs'
    @app.set 'views', 'src/views/'
    @app.use '/public', express.static(__dirname + '/public')

    routes(@app, @mongo, @slack)

    @app.set 'port', process.env.PORT || 5000
    @app.listen @app.get('port'), ->
      console.log "Node app is running on port 5000"

  it 'should return 400 for an empty message', (done) ->

    request(@app)
      .post('/message/user1')
      .expect(400, done);

  it 'should send a message to a user', (done) ->

    request(@app)
      .post('/message/U08CKGJ90')
      .send({ message: 'this is a test message' })
      .end (err, res) ->
        setTimeout ->
          postMessageStub.called.should.be.equal true
          done()
        , 100