###################################################################
# Setup the tests
###################################################################
should     = require 'should'
timeHelper = require '../src/helper/timeHelper'

###################################################################
# Helper
###################################################################

describe 'TimeHelper', ->

  it 'should return true if timestamp is older than 24 hours', ->
    timestamp = Date.now() - (86401 * 1000);
    hasExpired = timeHelper.hasTimestampExpired 24, timestamp
    hasExpired.should.be.equal true

  it 'should return true when date is a weekend', ->
    timestamp = Date.parse 'Sat, 02 May 2015 15:00:00 GMT'
    isWeekend = timeHelper.isWeekend timestamp, 0
    isWeekend.should.be.equal true

  it 'should return false when date is a weekday due to timezone diff', ->
    timestamp = Date.parse 'Sun, 03 May 2015 20:00:00 GMT'
    isWeekend = timeHelper.isWeekend timestamp, 5
    isWeekend.should.be.equal false

  it 'should return true when date is a weekend in a specific timezone', ->
    timestamp = Date.parse 'Fri, 22 May 2015 20:00:00 GMT'
    isWeekend = timeHelper.isWeekend timestamp, 8
    isWeekend.should.be.equal true

  it 'should return the current local time for a UTC date plus timezone difference', ->
    timestamp = Date.parse 'Fri, 22 May 2015 15:00:00 GMT'
    diff = 8
    localDate = timeHelper.getLocalDate timestamp, diff
    localDate.getUTCHours().should.be.equal 23

  it 'should return true if time falls between a specific interval', ->
    intervalMin = 6
    intervalMax = 10
    date = new Date 'Wed, 20 May 2015 08:30:00 GMT'
    isInsideInterval = timeHelper.isDateInsideInterval intervalMin, intervalMax, date
    isInsideInterval.should.be.equal true