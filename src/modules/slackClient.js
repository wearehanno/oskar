var EventEmitter, InputHelper, Promise, Slack, SlackClient, config, mongoClient, timeHelper,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Slack = require('../vendor/client');

mongoClient = require('../modules/mongoClient');

InputHelper = require('../helper/inputHelper');

timeHelper = require('../helper/timeHelper');

Promise = require('promise');

EventEmitter = require('events').EventEmitter;

config = require('config');

SlackClient = (function(_super) {
  __extends(SlackClient, _super);

  SlackClient.slack = null;

  SlackClient.mongo = null;

  function SlackClient(mongo, token) {
    if (mongo == null) {
      mongo = null;
    }
    if (token == null) {
      token = null;
    }
    this.messageHandler = __bind(this.messageHandler, this);
    this.presenceChangeHandler = __bind(this.presenceChangeHandler, this);
    this.setUserPresence = __bind(this.setUserPresence, this);
    this.token = process.env.SLACK_TOKEN || config.get('slack.token');
    this.token = token || this.token;
    this.autoReconnect = true;
    this.autoMark = true;
    this.users = [];
    this.channels = [];
    this.disabledUsers = process.env.DISABLED_USERS ? JSON.parse("[" + process.env.DISABLED_USERS + "]") : config.get('slack.disabledUsers');
    this.disabledChannels = process.env.DISABLED_CHANNELS ? JSON.parse("[" + process.env.DISABLED_CHANNELS + "]") : config.get('slack.disabledChannels');
    if (mongo != null) {
      this.mongo = mongo;
    }
  }

  SlackClient.prototype.connect = function() {
    var promise;
    console.log('connecting...');
    this.slack = new Slack(this.token, this.autoReconnect, this.autoMark);
    this.slack.on('presenceChange', this.presenceChangeHandler);
    this.slack.on('message', this.messageHandler);
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        _this.slack.on('open', function() {
          var attrs, user, _ref;
          _ref = _this.slack.users;
          for (user in _ref) {
            attrs = _ref[user];
            if (attrs.is_bot === false) {
              _this.users.push(attrs);
            }
          }
          return resolve(_this.slack);
        });
        _this.slack.on('error', function(error) {
          return reject(error);
        });
        return _this.slack.login();
      };
    })(this));
  };

  SlackClient.prototype.getUsers = function() {
    var users;
    users = this.users.filter((function(_this) {
      return function(user) {
        return _this.disabledUsers.indexOf(user.id) === -1;
      };
    })(this));
    return users;
  };

  SlackClient.prototype.getUserIds = function() {
    var users;
    return users = this.getUsers().map(function(user) {
      return user.id;
    });
  };

  SlackClient.prototype.getUser = function(userId) {
    var filteredUsers, user;
    if (this.disabledUsers.indexOf(userId) !== -1) {
      return null;
    }
    filteredUsers = (function() {
      var _i, _len, _ref, _results;
      _ref = this.users;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        user = _ref[_i];
        if (user.id === userId) {
          _results.push(user);
        }
      }
      return _results;
    }).call(this);
    return filteredUsers[0];
  };

  SlackClient.prototype.setUserPresence = function(userId, presence) {
    var user, _i, _len, _ref, _results;
    _ref = this.users;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      user = _ref[_i];
      if (user.id === userId) {
        _results.push(user.presence = presence);
      }
    }
    return _results;
  };

  SlackClient.prototype.allowUserComment = function(userId) {
    var user;
    user = this.getUser(userId);
    return user.allowComment = true;
  };

  SlackClient.prototype.disallowUserComment = function(userId) {
    var user;
    user = this.getUser(userId);
    return user.allowComment = false;
  };

  SlackClient.prototype.isUserCommentAllowed = function(userId) {
    var user;
    user = this.getUser(userId);
    return typeof user !== 'undefined' && typeof user.allowComment !== 'undefined' && user.allowComment;
  };

  SlackClient.prototype.getfeedbackRequestsCount = function(userId) {
    var user;
    user = this.getUser(userId);
    if (typeof user !== 'undefined' && typeof user.feedbackRequestsCount !== 'undefined' && user.feedbackRequestsCount) {
      return user.feedbackRequestsCount;
    }
    return 0;
  };

  SlackClient.prototype.setfeedbackRequestsCount = function(userId, count) {
    var user;
    user = this.getUser(userId);
    return user.feedbackRequestsCount = count;
  };

  SlackClient.prototype.presenceChangeHandler = function(data, presence) {
    data = {
      userId: data.id,
      status: presence
    };
    this.setUserPresence(data.userId, presence);
    return this.emit('presence', data);
  };

  SlackClient.prototype.messageHandler = function(message) {
    if ((message == null) || (this.getUser(message.user)) === void 0) {
      return false;
    }
    if (this.disabledChannels.indexOf(message.channel) !== -1) {
      return false;
    }
    message.type = 'input';
    return this.emit('message', message);
  };

  SlackClient.prototype.postMessage = function(userId, message) {
    if ((__indexOf.call(this.channels, userId) >= 0)) {
      return this.slack.postMessage(this.channels[userId].channel.id, message, function() {});
    }
    return this.slack.openDM(userId, (function(_this) {
      return function(res) {
        _this.channels[userId] = res;
        return _this.slack.postMessage(res.channel.id, message, function() {});
      };
    })(this));
  };

  SlackClient.prototype.postMessageToChannel = function(channelId, message, cb) {
    var res;
    return res = this.slack.postMessage(channelId, message, function() {
      if (cb) {
        return cb.apply(null, arguments);
      }
    });
  };

  return SlackClient;

})(EventEmitter);

module.exports = SlackClient;
