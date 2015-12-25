time = require('time')(Date);

class TimeHelper

  # pass an interval in hours and compare to timestamp
  @hasTimestampExpired: (intervalInHours, timestamp) ->
    intervalInSeconds = intervalInHours * 3600 * 1000
    nowMinusInterval = (time.time() * 1000) - intervalInSeconds

    if (timestamp < nowMinusInterval)
      return true
    false

  @isWeekend: (timestamp, diff = 0) ->
    date = @getLocalDate timestamp, diff
    (date.getUTCDay() is 6 or date.getUTCDay() is 0)

  @getUTCDate: ->
    now = new time.Date()
    now.setTimezone 'UTC'

  # get local date of user by adding difference to UTC timestamp
  @getLocalDate: (timestamp, diff) ->

    if timestamp is null
      date = @getUTCDate()
    else
      date = new time.Date timestamp
      date.setTimezone 'UTC'

    newHours = date.getUTCHours() + diff
    new Date(date.setUTCHours newHours)

  @isDateInsideInterval: (min, max, date) ->
    min <= date.getUTCHours() < max

module.exports = TimeHelper