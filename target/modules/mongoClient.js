var Mongo, MongoClient, Promise, config;

Mongo = require('mongodb').MongoClient;

Promise = require('promise');

config = require('config');

MongoClient = (function() {
  MongoClient.db = null;

  MongoClient.collection = null;

  function MongoClient(url) {
    if (url) {
      this.url = url;
    } else {
      this.url = process.env.MONGOLAB_URI || config.get('mongo.url');
    }
  }

  MongoClient.prototype.connect = function() {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return Mongo.connect(_this.url, function(err, db) {
          if (err === null) {
            _this.collection = db.collection('users');
            return resolve(db);
          } else {
            db.close();
            return reject();
          }
        });
      };
    })(this));
  };

  MongoClient.prototype.userExists = function(userId) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.collection.find({
          id: userId
        }).toArray(function(err, docs) {
          return resolve(docs.length > 0);
        });
      };
    })(this));
  };

  MongoClient.prototype.saveUser = function(user) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.userExists(user.id).then(function(res) {
          var userObj;
          if (res === true) {
            return resolve(user);
          }
          userObj = {
            id: user.id,
            name: user.name,
            real_name: user.real_name,
            tz: user.tz,
            tz_offset: user.tz_offset,
            image_48: user.profile.image_48
          };
          return _this.collection.insert(userObj, function(err, result) {
            if (err === null) {
              return resolve(result);
            } else {
              return reject();
            }
          });
        });
      };
    })(this));
  };

  MongoClient.prototype.saveUserStatus = function(userId, status) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        var update, user;
        user = {
          id: userId
        };
        update = {
          $push: {
            activity: {
              status: status,
              timestamp: Date.now()
            }
          }
        };
        return _this.collection.update(user, update, function(err, result) {
          if (err === null) {
            return resolve(result);
          } else {
            return reject();
          }
        });
      };
    })(this));
  };

  MongoClient.prototype.saveUserFeedback = function(userId, feedback) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        var update, user;
        user = {
          id: userId
        };
        update = {
          $push: {
            feedback: {
              status: feedback,
              timestamp: Date.now()
            }
          }
        };
        return _this.collection.update(user, update, function(err, result) {
          if (err === null) {
            return resolve(result);
          } else {
            return reject();
          }
        });
      };
    })(this));
  };

  MongoClient.prototype.saveUserFeedbackMessage = function(userId, feedbackMessage) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.getLatestUserTimestampForProperty('feedback', userId).then(function(res) {
          var find, update;
          find = {
            id: userId,
            feedback: {
              $elemMatch: {
                timestamp: res
              }
            }
          };
          update = {
            $set: {
              'feedback.$.message': feedbackMessage
            }
          };
          return _this.collection.update(find, update, function(err, result) {
            if (err === null) {
              return resolve(result);
            } else {
              return reject();
            }
          });
        });
      };
    })(this));
  };

  MongoClient.prototype.getUserData = function(userId) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.collection.find({
          id: userId
        }).toArray(function(err, docs) {
          if (err === !null) {
            return reject();
          }
          if (docs.length === 0) {
            return resolve(false);
          }
          return resolve(docs[0]);
        });
      };
    })(this));
  };

  MongoClient.prototype.getLatestUserFeedback = function(userId) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.collection.find({
          id: userId
        }).toArray(function(err, docs) {
          var feedback, obj, timestamp, _i, _len, _ref;
          if (err === !null) {
            return reject();
          }
          if (docs.length === 0) {
            return resolve(false);
          }
          if (!docs[0].hasOwnProperty('feedback')) {
            return resolve(null);
          }
          timestamp = 0;
          feedback = null;
          _ref = docs[0].feedback;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            obj = _ref[_i];
            if (obj.timestamp > timestamp) {
              timestamp = obj.timestamp;
              feedback = obj;
            }
          }
          return resolve(feedback);
        });
      };
    })(this));
  };

  MongoClient.prototype.getAllUserFeedback = function(userIds) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.collection.find({
          id: {
            $in: userIds
          }
        }).toArray(function(err, docs) {
          var users;
          if (err !== null) {
            reject();
          }
          users = docs.map(function(elem) {
            var feedback, res;
            feedback = null;
            if (elem.feedback) {
              elem.feedback.sort(function(a, b) {
                return a.timestamp > b.timestamp;
              });
              feedback = elem.feedback.pop();
            }
            return res = {
              id: elem.id,
              feedback: feedback
            };
          });
          return resolve(users);
        });
      };
    })(this));
  };

  MongoClient.prototype.getUserFeedbackCount = function(userId, date) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.collection.find({
          id: userId
        }).toArray(function(err, docs) {
          var day, filtered, month;
          if (err === !null) {
            return reject();
          }
          if (docs.length === 0) {
            return resolve(false);
          }
          filtered = [];
          day = date.getDate();
          month = date.getMonth();
          if (docs[0].feedback) {
            filtered = docs[0].feedback.filter(function(feedback) {
              date = new Date(feedback.timestamp);
              return date.getDate() === day && date.getMonth() === month;
            });
            return resolve(filtered.length);
          }
          return resolve(0);
        });
      };
    })(this));
  };

  MongoClient.prototype.getLatestUserTimestampForProperty = function(property, userId) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.collection.find({
          id: userId
        }).toArray(function(err, docs) {
          if (err === !null) {
            return reject();
          }
          if (docs.length === 0) {
            return resolve(false);
          }
          if (!docs[0].hasOwnProperty(property)) {
            return resolve(null);
          }
          docs[0][property].sort(function(a, b) {
            return a.timestamp > b.timestamp;
          });
          return resolve(docs[0][property].pop().timestamp);
        });
      };
    })(this));
  };

  MongoClient.prototype.getOnboardingStatus = function(userId) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.collection.find({
          id: userId
        }).toArray(function(err, docs) {
          if (err === !null) {
            return reject();
          }
          if (docs.length === 0) {
            return resolve(false);
          }
          if (!docs[0].hasOwnProperty('onboarding')) {
            return resolve(0);
          }
          return resolve(docs[0].onboarding);
        });
      };
    })(this));
  };

  MongoClient.prototype.setOnboardingStatus = function(userId, status) {
    var promise;
    return promise = new Promise((function(_this) {
      return function(resolve, reject) {
        var find, update;
        find = {
          id: userId
        };
        update = {
          $set: {
            'onboarding': status
          }
        };
        return _this.collection.update(find, update, function(err, result) {
          if (err === null) {
            return resolve(result);
          } else {
            return reject();
          }
        });
      };
    })(this));
  };

  return MongoClient;

})();

module.exports = MongoClient;
