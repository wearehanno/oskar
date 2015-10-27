var InputHelper;

InputHelper = (function() {
  function InputHelper() {}

  InputHelper.isValidStatus = function(status) {
    var numberPattern;
    numberPattern = /^[1-5]$/;
    if (!status.match(numberPattern)) {
      return false;
    }
    return true;
  };

  InputHelper.isAskingForUserStatus = function(input) {
    var response, userPattern;
    userPattern = /^How is <[@|\!](\w+)>\s?\??$/i;
    response = input.match(userPattern);
    if (response != null) {
      return response[1];
    }
    return null;
  };

  InputHelper.isAskingForHelp = function(input) {
    var messagePattern;
    messagePattern = /help/i;
    if (input.match(messagePattern)) {
      return true;
    }
    return false;
  };

  InputHelper.isStatusAndFeedback = function(input) {
    var matches, messagePattern, obj;
    messagePattern = /^(\d):\s*([\w\s\:\.,-]+)/i;
    matches = input.match(messagePattern);
    if (matches === null) {
      return false;
    }
    return obj = {
      status: matches[1],
      message: matches[2]
    };
  };

  return InputHelper;

})();

module.exports = InputHelper;
