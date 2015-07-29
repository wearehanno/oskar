var TimeHelper, time;

time = require('time')(Date);

TimeHelper = (function() {
  function TimeHelper() {}

  TimeHelper.hasTimestampExpired = function(intervalInHours, timestamp) {
    var intervalInSeconds, nowMinusInterval;
    intervalInSeconds = intervalInHours * 3600 * 1000;
    nowMinusInterval = (time.time() * 1000) - intervalInSeconds;
    if (timestamp < nowMinusInterval) {
      return true;
    } else {
      return false;
    }
  };

  TimeHelper.isWeekend = function(timestamp, diff) {
    var date;
    if (diff == null) {
      diff = 0;
    }
    date = this.getLocalDate(timestamp, diff);
    return date.getUTCDay() === 6 || date.getUTCDay() === 0;
  };

  TimeHelper.getUTCDate = function() {
    var now;
    now = new time.Date();
    return now.setTimezone('UTC');
  };

  TimeHelper.getLocalDate = function(timestamp, diff) {
    var date, newHours;
    if (timestamp === null) {
      date = this.getUTCDate();
    } else {
      date = new time.Date(timestamp);
      date.setTimezone('UTC');
    }
    newHours = date.getUTCHours() + diff;
    return new Date(date.setUTCHours(newHours));
  };

  TimeHelper.isDateInsideInterval = function(min, max, date) {
    var _ref;
    return (min <= (_ref = date.getUTCHours()) && _ref < max);
  };

  return TimeHelper;

})();

module.exports = TimeHelper;
