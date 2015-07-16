var InputHelper, MongoClient, OnboardingHelper, Oskar, OskarTexts, SlackClient, TimeHelper, express, routes,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

express = require('express');

MongoClient = require('./modules/mongoClient');

SlackClient = require('./modules/slackClient');

routes = require('./modules/routes');

TimeHelper = require('./helper/timeHelper');

InputHelper = require('./helper/inputHelper');

OnboardingHelper = require('./helper/onboardingHelper');

OskarTexts = require('./content/oskarTexts');

Oskar = (function() {
  function Oskar(mongo, slack, onboardingHelper) {
    this.checkForUserStatus = __bind(this.checkForUserStatus, this);
    this.handleFeedbackMessage = __bind(this.handleFeedbackMessage, this);
    this.revealStatusForUser = __bind(this.revealStatusForUser, this);
    this.revealStatusForChannel = __bind(this.revealStatusForChannel, this);
    this.revealStatus = __bind(this.revealStatus, this);
    this.onboardingHandler = __bind(this.onboardingHandler, this);
    this.messageHandler = __bind(this.messageHandler, this);
    this.presenceHandler = __bind(this.presenceHandler, this);
    this.setupEvents = __bind(this.setupEvents, this);
    this.app = express();
    this.app.set('view engine', 'ejs');
    this.app.set('views', 'src/views/');
    this.app.use('/public', express["static"](__dirname + '/public'));
    this.mongo = mongo || new MongoClient();
    this.mongo.connect();
    this.slack = slack || new SlackClient();
    this.slack.connect().then((function(_this) {
      return function() {
        return _this.onboardingHelper.retainOnboardingStatusForUsers(_this.slack.getUserIds());
      };
    })(this));
    this.onboardingHelper = onboardingHelper || new OnboardingHelper(this.mongo);
    this.setupRoutes();
    if (process.env.NODE_ENV === 'development') {
      return;
    }
    this.setupEvents();
    setInterval((function(_this) {
      return function() {
        return _this.checkForUserStatus(_this.slack);
      };
    })(this), 3600 * 1000);
  }

  Oskar.prototype.setupEvents = function() {
    this.slack.on('presence', this.presenceHandler);
    this.slack.on('message', this.messageHandler);
    return this.onboardingHelper.on('message', this.onboardingHandler);
  };

  Oskar.prototype.setupRoutes = function() {
    routes(this.app, this.mongo, this.slack);
    this.app.set('port', process.env.PORT || 5000);
    return this.app.listen(this.app.get('port'), function() {
      return console.log("Node app is running on port 5000");
    });
  };

  Oskar.prototype.presenceHandler = function(data) {
    var user;
    user = this.slack.getUser(data.userId);
    if (user === null) {
      return false;
    }
    if (data.status === 'triggered') {
      this.slack.disallowUserComment(data.userId);
    }
    user = this.slack.getUser(data.userId);
    if (user && user.presence !== 'active') {
      return;
    }
    if (!this.onboardingHelper.isOnboarded(data.userId)) {
      return this.onboardingHelper.welcome(data.userId);
    }
    return this.mongo.userExists(data.userId).then((function(_this) {
      return function(res) {
        if (!res) {
          return _this.mongo.saveUser(user).then(function(res) {
            return _this.requestUserFeedback(data.userId, data.status);
          });
        } else {
          return _this.requestUserFeedback(data.userId, data.status);
        }
      };
    })(this));
  };

  Oskar.prototype.messageHandler = function(message) {
    var userId;
    if (!this.onboardingHelper.isOnboarded(message.user)) {
      return this.onboardingHelper.advance(message.user, message.text);
    }
    if (userId = InputHelper.isAskingForUserStatus(message.text)) {
      return this.revealStatus(userId, message);
    }
    if (this.slack.isUserCommentAllowed(message.user)) {
      return this.handleFeedbackMessage(message);
    }
    if (InputHelper.isAskingForHelp(message.text)) {
      return this.composeMessage(message.user, 'faq');
    }
    return this.mongo.getLatestUserTimestampForProperty('feedback', message.user).then((function(_this) {
      return function(timestamp) {
        return _this.evaluateFeedback(message, timestamp);
      };
    })(this));
  };

  Oskar.prototype.onboardingHandler = function(message) {
    return this.composeMessage(message.userId, message.type);
  };

  Oskar.prototype.requestUserFeedback = function(userId, status) {
    var date, user;
    this.mongo.saveUserStatus(userId, status);
    if (status !== 'active' && status !== 'triggered') {
      return;
    }
    user = this.slack.getUser(userId);
    date = TimeHelper.getLocalDate(null, user.tz_offset / 3600);
    if (TimeHelper.isWeekend() || TimeHelper.isDateInsideInterval(0, 8, date)) {
      return;
    }
    return this.mongo.getLatestUserTimestampForProperty('feedback', userId).then((function(_this) {
      return function(timestamp) {
        var today;
        if (timestamp === false) {
          return;
        }
        today = new Date();
        return _this.mongo.getUserFeedbackCount(userId, today).then(function(count) {
          var requestsCount;
          if (count < 2 && TimeHelper.hasTimestampExpired(6, timestamp)) {
            requestsCount = _this.slack.getfeedbackRequestsCount(userId);
            _this.slack.setfeedbackRequestsCount(userId, requestsCount + 1);
            return _this.composeMessage(userId, 'requestFeedback', requestsCount);
          }
        });
      };
    })(this));
  };

  Oskar.prototype.evaluateFeedback = function(message, latestFeedbackTimestamp, firstFeedback) {
    if (firstFeedback == null) {
      firstFeedback = false;
    }
    if (latestFeedbackTimestamp && !TimeHelper.hasTimestampExpired(4, latestFeedbackTimestamp)) {
      return this.composeMessage(message.user, 'alreadySubmitted');
    }
    if (!InputHelper.isValidStatus(message.text)) {
      return this.composeMessage(message.user, 'invalidInput');
    }
    this.mongo.saveUserFeedback(message.user, message.text);
    this.slack.setfeedbackRequestsCount(message.user, 0);
    this.slack.allowUserComment(message.user);
    if (parseInt(message.text) < 3) {
      return this.composeMessage(message.user, 'lowFeedback');
    }
    if (parseInt(message.text) === 3) {
      return this.composeMessage(message.user, 'averageFeedback');
    }
    if (parseInt(message.text) > 3) {
      return this.composeMessage(message.user, 'highFeedback');
    }
    return this.composeMessage(message.user, 'feedbackReceived');
  };

  Oskar.prototype.revealStatus = function(userId, message) {
    if (userId === 'channel') {
      return this.revealStatusForChannel(message.user);
    } else {
      return this.revealStatusForUser(message.user, userId);
    }
  };

  Oskar.prototype.revealStatusForChannel = function(userId) {
    var userIds;
    userIds = this.slack.getUserIds();
    return this.mongo.getAllUserFeedback(userIds).then((function(_this) {
      return function(res) {
        return _this.composeMessage(userId, 'revealChannelStatus', res);
      };
    })(this));
  };

  Oskar.prototype.revealStatusForUser = function(userId, targetUserId) {
    var userObj;
    userObj = this.slack.getUser(targetUserId);
    if (userObj === null) {
      return;
    }
    return this.mongo.getLatestUserFeedback(targetUserId).then((function(_this) {
      return function(res) {
        if (res === null) {
          res = {};
        }
        res.user = userObj;
        return _this.composeMessage(userId, 'revealUserStatus', res);
      };
    })(this));
  };

  Oskar.prototype.handleFeedbackMessage = function(message) {
    this.slack.disallowUserComment(message.user);
    this.mongo.saveUserFeedbackMessage(message.user, message.text);
    this.composeMessage(message.user, 'feedbackMessageReceived');
    return this.mongo.getLatestUserFeedback(message.user).then((function(_this) {
      return function(res) {
        return _this.broadcastUserStatus(message.user, res.status, message.text);
      };
    })(this));
  };

  Oskar.prototype.broadcastUserStatus = function(userId, status, feedback) {
    var user, userIds, userStatus;
    user = this.slack.getUser(userId);
    userStatus = {
      first_name: user.profile.first_name,
      status: status,
      feedback: feedback
    };
    userIds = this.slack.getUserIds();
    return userIds.forEach((function(_this) {
      return function(user) {
        return _this.composeMessage(user, 'newUserFeedback', userStatus);
      };
    })(this));
  };

  Oskar.prototype.composeMessage = function(userId, messageType, obj) {
    var random, statusMsg, userObj;
    random = Math.floor(Math.random() * (4 - 1)) + 1;
    if (messageType === 'requestFeedback') {
      userObj = this.slack.getUser(userId);
      if (obj < 1) {
        statusMsg = OskarTexts.requestFeedback.random[random - 1].format(userObj.profile.first_name);
        statusMsg += OskarTexts.requestFeedback.selection;
      } else {
        statusMsg = OskarTexts.requestFeedback.options[obj - 1];
      }
    } else if (messageType === 'revealChannelStatus') {
      statusMsg = "";
      obj.forEach((function(_this) {
        return function(user) {
          userObj = _this.slack.getUser(user.id);
          statusMsg += OskarTexts.revealChannelStatus.status.format(userObj.profile.first_name, user.feedback.status);
          if (user.feedback.message) {
            statusMsg += OskarTexts.revealChannelStatus.message.format(user.feedback.message);
          }
          return statusMsg += "\r\n";
        };
      })(this));
    } else if (messageType === 'revealUserStatus') {
      if (!obj.status) {
        statusMsg = OskarTexts.revealUserStatus.error.format(obj.user.profile.first_name);
      } else {
        statusMsg = OskarTexts.revealUserStatus.status.format(obj.user.profile.first_name, obj.status);
        if (obj.message) {
          statusMsg += OskarTexts.revealUserStatus.message.format(obj.message);
        }
      }
    } else if (messageType === 'newUserFeedback') {
      statusMsg = OskarTexts.newUserFeedback.format(obj.first_name, obj.status, obj.feedback);
    } else if (messageType === 'faq') {
      statusMsg = OskarTexts.faq;
    } else {
      statusMsg = OskarTexts[messageType];
    }
    if (userId && statusMsg) {
      return this.slack.postMessage(userId, statusMsg);
    }
  };

  Oskar.prototype.checkForUserStatus = function(slack) {
    var userIds;
    userIds = slack.getUserIds();
    return userIds.forEach(function(userId) {
      var data;
      data = {
        userId: userId,
        status: 'triggered'
      };
      return slack.emit('presence', data);
    });
  };

  return Oskar;

})();

module.exports = Oskar;
