var OskarTexts, basicAuth, config, routes;

OskarTexts = require('../content/oskarTexts');

basicAuth = require('basic-auth-connect');

config = require('config');

routes = function(app, mongo, slack) {
  var auth, password, username;
  app.get('/', (function(_this) {
    return function(req, res) {
      return res.render('pages/index');
    };
  })(this));
  app.get('/faq', (function(_this) {
    return function(req, res) {
      return res.render('pages/faq');
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
  username = process.env.AUTH_USERNAME || config.get('auth.username');
  password = process.env.AUTH_PASSWORD || config.get('auth.password');
  auth = basicAuth(username, password);
  app.get('/dashboard', auth, (function(_this) {
    return function(req, res) {
      var userIds, users;
      users = slack.getUsers();
      if (users.length === 0) {
        res.render('pages/dashboard');
      }
      userIds = users.map(function(user) {
        return user.id;
      });
      return mongo.getAllUserFeedback(userIds).then(function(statuses) {
        var filteredStatuses;
        filteredStatuses = [];
        if (statuses.length) {
          statuses.forEach(function(status) {
            filteredStatuses[status.id] = status.feedback;
            filteredStatuses[status.id].date = new Date(status.feedback.timestamp);
            return filteredStatuses[status.id].statusString = OskarTexts.statusText[status.feedback.status];
          });
          if (statuses.length > 1) {
            users.sort(function(a, b) {
              return filteredStatuses[a.id].status > filteredStatuses[b.id].status;
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
  return app.get('/status/:userId', (function(_this) {
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
};

module.exports = routes;
