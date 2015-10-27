var OskarTexts, basicAuth, bodyParser, config, jsonParser, routes;

OskarTexts = require('../content/oskarTexts');

basicAuth = require('basic-auth-connect');

bodyParser = require('body-parser');

config = require('config');

jsonParser = bodyParser.json();

routes = function(app, mongo, slack) {
  var auth, password, username;
  username = process.env.AUTH_USERNAME || config.get('auth.username');
  password = process.env.AUTH_PASSWORD || config.get('auth.password');
  auth = basicAuth(username, password);
  app.get('/', auth, (function(_this) {
    return function(req, res) {
      var userIds, users;
      users = slack.getUsers();
      if (users.length === 0) {
        res.render('pages/index');
      }
      userIds = users.map(function(user) {
        return user.id;
      });
      return mongo.getAllUserFeedback(userIds).then(function(statuses) {
        var filteredStatuses, isSortingPossible;
        filteredStatuses = [];
        isSortingPossible = true;
        if (statuses.length) {
          statuses.forEach(function(status) {
            if (status.feedback !== null) {
              filteredStatuses[status.id] = status.feedback;
              filteredStatuses[status.id].date = new Date(status.feedback.timestamp);
              return filteredStatuses[status.id].statusString = OskarTexts.statusText[status.feedback.status];
            } else {
              return isSortingPossible = false;
            }
          });
          if (statuses.length > 1 && isSortingPossible) {
            if (users[0].status) {
              users.sort(function(a, b) {
                return filteredStatuses[a.id].status > filteredStatuses[b.id].status;
              });
            }
          }
        }
        return res.render('pages/index', {
          users: users,
          statuses: filteredStatuses
        });
      });
    };
  })(this));
  app.get('/signup', (function(_this) {
    return function(req, res) {
      return res.render('pages/signup');
    };
  })(this));
  app.get('/thank-you', (function(_this) {
    return function(req, res) {
      return res.render('pages/thank-you');
    };
  })(this));
  app.get('/status/:userId', (function(_this) {
    return function(req, res) {
      return mongo.getUserData(req.params.userId).then(function(data) {
        var graphData, userData;
        graphData = data.feedback.map(function(row) {
          return [row.timestamp, parseInt(row.status)];
        });
        userData = slack.getUser(data.id);
        userData.status = data.feedback[data.feedback.length - 1];
        userData.date = new Date(userData.status.timestamp);
        userData.statusString = OskarTexts.statusText[userData.status.status];
        return res.render('pages/status', {
          userData: userData,
          graphData: JSON.stringify(graphData)
        });
      });
    };
  })(this));
  return app.post('/message/:userId', jsonParser, (function(_this) {
    return function(req, res) {
      if (!req.body.message) {
        return res.status(400).send({
          status: 'fail'
        });
      }
      slack.postMessage(req.params.userId, req.body.message);
      return res.json({
        status: 'ok'
      });
    };
  })(this));
};

module.exports = routes;
