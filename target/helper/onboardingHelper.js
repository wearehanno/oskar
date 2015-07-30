var EventEmitter, InputHelper, OnboardingHelper,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

InputHelper = require('./inputHelper');

EventEmitter = require('events').EventEmitter;

OnboardingHelper = (function(_super) {
  __extends(OnboardingHelper, _super);

  function OnboardingHelper(mongo, userIds) {
    this.advance = __bind(this.advance, this);
    this.welcome = __bind(this.welcome, this);
    this.retainOnboardingStatusForUser = __bind(this.retainOnboardingStatusForUser, this);
    this.retainOnboardingStatusForUsers = __bind(this.retainOnboardingStatusForUsers, this);
    this.mongo = mongo;
    this.onboardingStatus = {};
  }

  OnboardingHelper.prototype.retainOnboardingStatusForUsers = function(userIds) {
    return userIds.forEach(this.retainOnboardingStatusForUser);
  };

  OnboardingHelper.prototype.retainOnboardingStatusForUser = function(userId) {
    return this.mongo.getOnboardingStatus(userId).then((function(_this) {
      return function(res) {
        return _this.onboardingStatus[userId] = res;
      };
    })(this));
  };

  OnboardingHelper.prototype.isOnboarded = function(userId) {
    return this.onboardingStatus[userId] === 3;
  };

  OnboardingHelper.prototype.getOnboardingStatus = function(userId) {
    return this.onboardingStatus[userId];
  };

  OnboardingHelper.prototype.setOnboardingStatus = function(userId, status) {
    this.onboardingStatus[userId] = status;
    if (status === 3) {
      return this.mongo.setOnboardingStatus(userId, status);
    }
  };

  OnboardingHelper.prototype.welcome = function(userId) {
    var data;
    if (this.getOnboardingStatus(userId) > 0) {
      return;
    }
    data = {
      userId: userId,
      type: 'introduction'
    };
    this.setOnboardingStatus(userId, 1);
    return this.emit('message', data);
  };

  OnboardingHelper.prototype.advance = function(userId, message) {
    var data, status;
    if (message == null) {
      message = null;
    }
    status = this.getOnboardingStatus(userId);
    if (status === 0) {
      return;
    }
    data = {
      userId: userId,
      type: 'firstMessage'
    };
    if (status === 1) {
      this.setOnboardingStatus(userId, 2);
      this.emit('message', data);
      return;
    }
    if (!message || !InputHelper.isValidStatus(message)) {
      data.type = 'firstMessageFailure';
      this.emit('message', data);
      return;
    }
    this.setOnboardingStatus(userId, 3);
    this.mongo.saveUserFeedback(userId, message);
    data.type = 'firstMessageSuccess';
    return this.emit('message', data);
  };

  return OnboardingHelper;

})(EventEmitter);

module.exports = OnboardingHelper;
