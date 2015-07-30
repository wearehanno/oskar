var Message,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Message = (function() {
  function Message(_client, data) {
    var k;
    this._client = _client;
    if (data == null) {
      data = {};
    }
    this.deleteMessage = __bind(this.deleteMessage, this);
    this.updateMessage = __bind(this.updateMessage, this);
    for (k in data || {}) {
      this[k] = data[k];
    }
  }

  Message.prototype.toJSON = function() {
    var m;
    m = {};
    m['id'] = this.id ? this.id : 1;
    m['type'] = this.type ? this.type : 'message';
    m['channel'] = this.channel;
    m['text'] = this.text;
    return m;
  };

  Message.prototype.getBody = function() {
    var attach, k, txt, _ref;
    txt = "";
    if (this.text) {
      txt += this.text;
    }
    if (this.attachments) {
      if (this.text) {
        txt += "\n";
      }
      _ref = this.attachments;
      for (k in _ref) {
        attach = _ref[k];
        if (k > 0) {
          txt += "\n";
        }
        txt += attach.fallback;
      }
    }
    return txt;
  };

  Message.prototype.toString = function() {
    var body, channel, str, user;
    if (this.hidden) {
      return '';
    }
    if (!this.text && !this.attachments) {
      return '';
    }
    str = "";
    channel = this._client.getChannelGroupOrDMByID(this.channel);
    if (channel) {
      str += channel.name + ' > ';
    }
    user = this._client.getUserByID(this.user);
    if (user) {
      str += user.name + ': ';
    } else if (this.username) {
      str += this.username;
      if (this._client.getUserByName(this.username)) {
        str += ' (bot): ';
      } else {
        str += ': ';
      }
    }
    body = this.getBody();
    if (body) {
      str += body;
    }
    return str;
  };

  Message.prototype.getChannelType = function() {
    var channel;
    channel = this._client.getChannelGroupOrDMByID(this.channel);
    if (!channel) {
      return '';
    }
    return channel.getType();
  };

  Message.prototype.updateMessage = function(new_text) {
    var params;
    params = {
      "ts": this.ts,
      "channel": this.channel,
      "text": new_text
    };
    if (this.ts) {
      this._client.logger.debug("Sending message change request");
      this._client.logger.debug(params);
      return this._client._apiCall("chat.update", params, this._onUpdateMessage);
    }
  };

  Message.prototype._onUpdateMessage = function(data) {
    return this._client.logger.debug(data);
  };

  Message.prototype.deleteMessage = function() {
    var params;
    params = {
      "ts": this.ts,
      "channel": this.channel
    };
    if (this.ts) {
      this._client.logger.debug("Sending message delete request");
      this._client.logger.debug(params);
      return this._client._apiCall("chat.delete", params, this._onDeleteMessage);
    }
  };

  Message.prototype._onDeleteMessage = function(data) {
    return this._client.logger.debug(data);
  };

  Message.prototype._onMessageSent = function(data) {
    return this.ts = data.ts;
  };

  return Message;

})();

module.exports = Message;
