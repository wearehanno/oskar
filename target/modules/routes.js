var OskarTexts, basicAuth, bodyParser, config, jsonParser, routes;

OskarTexts = require('../content/oskarTexts');

basicAuth = require('basic-auth-connect');

bodyParser = require('body-parser');

config = require('config');

jsonParser = bodyParser.json();

routes = function(app, mongo, slack) {
  var auth, password, username;
  app.get('/faq', (function(_this) {
    return function(req, res) {
      console.log("GET /faq");
      return res.render('pages/faq');
    };
  })(this));
  username = process.env.AUTH_USERNAME || config.get('auth.username');
  password = process.env.AUTH_PASSWORD || config.get('auth.password');
  auth = basicAuth(username, password);
  app.get('/', auth, (function(_this) {
    return function(req, res) {
      var userIds, users;
      console.log("GET /dashboard");
      users = slack.getUsers();
      if (users.length === 0) {
        res.render('pages/dashboard');
      }
      userIds = users.map(function(user) {
        return user.id;
      });
      return mongo.getAllUserFeedback(userIds).then(function(slimUsers) {
        var filteredStatuses;
        filteredStatuses = [];
        if (slimUsers.length) {
          slimUsers.forEach(function(u) {
            if (u.feedback != null) {
              filteredStatuses[u.id] = u.feedback;
              filteredStatuses[u.id].date = new Date(u.feedback.timestamp);
              return filteredStatuses[u.id].statusString = OskarTexts.statusText[u.feedback.status];
            }
          });
          if (users.length > 1) {
            users.sort(function(a, b) {
              if (filteredStatuses[a.id] == null) {
                if (filteredStatuses[b.id] == null) {
                  return a.name.toLowerCase() < b.name.toLowerCase();
                } else {
                  return 1;
                }
              } else if (filteredStatuses[b.id] == null) {
                return -1;
              } else {
                return filteredStatuses[a.id].date < filteredStatuses[b.id].date;
              }
            });
          }
        }
        return res.render('pages/dashboard', {
          users: users,
          statuses: filteredStatuses
        });
      });
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
