var WebRocket = function(url, options) {
    this.connection = new WebRocket.Connection(url, options)
};

WebRocket.prototype = {
    constructor: WebRocket,

    bind: function(event, fn) {
        return this.connection.bind(event, fn);
    },

    unbind: function(event) {
        return this.connection.unbind(event);
    },

    broadcast: function(channel, event, data, trigger) {
        return this.connection.broadcast(channel, event, data, trigger);
    },

    trigger: function(event, data) {
        return this.connection.trigger(event, data);
    },

    subscribe: function(channel, data, hidden) {
        return this.connection.subscribe(channel, data, hidden);
    },
    
    unsubscribe: function(channel, data) {
        return this.connection.unsubscribe(channel, data);
    },

    authenticate: function(channels, uid) {
        return this.connection.authenticate(channels, uid);
    },

    close: function(data) {
        return this.connection.close(data);
    }
};

WebRocket.ConnectionState = {
    NOT_CONNECTED:  1,
    CONNECTING:     2,
    AUTHENTICATING: 4,
    CONNECTED:      4,
    CLOSING:        8,
    CLOSED:         16,
    BROKEN:         32
};

WebRocket.Connection = function WebRocketConnection(url, options) {
    options       = !!options ? options : {};
    this.url      = url;
    this.debug    = !!options.debug;
    this.authurl  = !!options.authURL ? options.authURL : '/webrocket/auth.json';
    this.state    = WebRocket.ConnectionState.NOT_CONNECTED;
    this.socket   = undefined;
    this.channels = new WebRocket.Channels(this);
    this.events   = new WebRocket.Events;
    this.auths    = [];

    this.connect();
};

WebRocket.Connection.prototype = {
    constructor: WebRocket.Connection,

    __unpack: function(data) {
        return JSON.parse(data);
    },

    __onopen: function(event) {
        this.state = WebRocket.ConnectionState.CONNECTING;

        if (this.debug) {
            console.log("D: WebRocket: Connecting");
        }
    },

    __onclose: function(event) {
        console.log("WebRocket: Unexpectedly closed connection");
        this.state  = WebRocket.ConnectionState.BROKEN;
        this.connect();
    },

    __onmessage: function(event) {
        var data = this.__unpack(event.data);
        var eventName = null;

        for (var key in data) {
            eventName = key;
            break;
        }
        if (this.debug) {
            console.log("D: WebRocket: Event received, " + event.data);
        }

        var handler = this['handler/' + eventName] || this['handler/*'];
        handler.call(this, eventName, data[eventName]);
    },

    __onerror: function(event) {
        // We're not fucking around. Reconnecting!
        console.log("WebRocket: Connection error", event);
        this.state  = WebRocket.ConnectionState.BROKEN;
        this.connect();
    },

    __authenticate: function(channels, uid) {
        // TODO: change it to work withut jQuery
        if (this.debug) {
            console.log("D: WebRocket: Authenticating");
        }
        var self = this;
        $.ajax(this.authurl + "?channel=" + channels + "&uid=" + uid, {
            success: function(data) {
                if (data.token) {
                    payload = { auth: { token: data.token } };
                    self.send(payload);
                }
            }
            // TODO: add error handling
        });
    },
    
    isConnected: function() {
        return this.state == WebRocket.ConnectionState.CONNECTED;
    },
    
    send: function(data) {
        if (!this.isConnected()) {
            console.log("WebRocket: Not connected");
            return false;
        }
        return this.socket.send(JSON.stringify(data));
    },
    
    connect: function() {
        var self = this;
        this.socket = new WebSocket(this.url);
        this.socket.onopen = function(e) { self.__onopen(e) };
        this.socket.onclose = function(e) { self.__onclose(e) };
        this.socket.onmessage = function(e) { self.__onmessage(e) };
        this.socket.onerror = function(e) { self.__onerror(e) };
    },

    authenticate: function(channels, uid) {
        this.auths.push({ channels: channels, uid: uid });
        if (this.isConnected()) {
            this.__authenticate(channels, uid);
        }
    },

    reauthenticate: function() {
        for (var i = 0; i < this.auths.length; i++) {
            var auth = this.auths[i];
            this.__authenticate(auth.channels, auth.uid);
        }
    },

    subscribe: function(channelName, data, hidden) {
        var channel = this.channels.get(channelName);
        if (!channel) channel = this.channels.add(channelName);
        channel.subscribe(data, hidden);
        return channel
    },

    unsubscribe: function(channelName, data) {
        var channel = this.channels.get(channelName);
        if (!channel) return false
        channel.unsubscribe(data);
        return channel
    },

    trigger: function(event, data) {
        payload = { trigger: { event: event, data: data } };
        return this.send(payload);
    },

    broadcast: function(channel, event, data, trigger) {
        var channel = this.channels.get(data.channel);
        if (!channel) return false
        return channel.broadcast(event, data, trigger);
    },

    close: function(data) {
        this.state = WebRocket.ConnectionState.CLOSING;
        // TODO: ...
    },

    bind: function(event, fn) {
        return this.events.bind(event, fn);
    },

    unbind: function(event) {
        return this.events.unbind(event);
    },
    
    'handler/:connected': function(event, data) {
        this.state = WebRocket.ConnectionState.CONNECTED;
        if (this.debug) {
            console.log("D: WebRocket: Connected");
        }
        if (this.auths.length > 0) {
            this.reauthenticate();
        } else {
            this.channels.subscribeAll();
        }
    },

    'handler/:subscribed': function(event, data) {
        var channel = this.channels.get(data.channel);
        if (!channel) return false;
        channel.subscription(true);
        this.events.trigger(':subscribe', data);
    },

    'handler/:unsubscribed': function(event, data) {
        var channel = this.channels.get(data.channel);
        if (!channel) return false;
        channel.subscription(false);
        this.events.trigger(':unsubscribe', data);
    },

    'handler/:memberJoined': function(event, data) {
        var channel = this.channels.get(data.channel);
        if (!channel) return false;
        channel.addMember(data);
        channel.trigger(':memberJoined', data);
    },

    'handler/:memberLeft': function(event, data) {
        var channel = this.channels.get(data.channel);
        if (!channel) return false;
        channel.delMember(data);
        channel.trigger(':memerLeft', data);
    },

    'handler/:authenticated': function(event, data) {
        if (this.debug) {
            console.log("D: WebRocket: Authenticated");
        }
        this.channels.subscribeAll();
    },

    'handler/:closed': function(event, data) {
        this.state = WebRocket.ConnectionState.CLOSED;
    },

    'handler/:error': function(event, data) {
        if (data.code == 402) {
            this.__authenticate();
        } else {
            console.log("WebRocket: Error " + data.code + " " + data.status);
        }
    },

    'handler/*': function(event, data) {
        var channelName = data.channel
        if (!!channelName) {
            var channel = this.channels.get(channelName);
            if (!channel) return false;
            channel.events.trigger(event, data);
        } else {
            this.events.trigger(event, data);
        }
    }
};

WebRocket.Events = function WebRocketEvents() {
    this.callbacks = {};
};

WebRocket.Events.prototype = {
    constructor: WebRocket.Events,
    
    bind: function(event, fn) {
        var callbacks = this.callbacks[event];
        if (!callbacks) this.callbacks[event] = [];
        this.callbacks[event].push(fn);
        return fn;
    },

    unbind: function(event) {
        delete(this.callbacks[event]);
    },
    
    trigger: function(event, data) {
        var callbacks = this.callbacks[event];
        if (callbacks) {
            for (var i = 0; i < callbacks.length; i++) {
                callbacks[i].call({}, data);
            }
        }
    }
};

WebRocket.SubscriptionState = {
    UNSUBSCRIBED:  1,
    SUBSCRIBING:   2,
    SUBSCRIBED:    4,
    UNSUBSCRIBING: 8
};

WebRocket.Channels = function WebRocketChannels(connection) {
    this.connection = connection;
    this.channels   = {};
};

WebRocket.Channels.prototype = {
    constructor: WebRocket.Channels,

    add: function(name) {
        var channel = this.get(name);
        if (channel) return channel;
        channel = new WebRocket.Channel(this.connection, name);
        this.channels[name] = channel;
        return channel;
    },

    del: function(name) {
        var channel = this.get(name);
        if (!channel) return false;
        delete(this.channels[name]);
        return true;
    },

    get: function(name) {
        return this.channels[name];
    },

    each: function(fn) {
        for (var channel in this.channels)
            fn(this.channels[channel]);
    },

    subscribeAll: function() {
        this.each(function(channel) {
            if (channel.isSubscribing()) {
                channel.subscribe(channel.data, channel.hidden);
            }
        });
    },

    unsubscribeAll: function(data) {
        this.each(function(channel) {
            channel.unsubscribe(data);
        });
    },

    unmarkAll: function(data) {
        this.each(function(channel) {
            channel.subscription(false);
        })
    }
};

WebRocket.Channel = function WebRocketChannel(connection, name, data) {
    this.connection = connection;
    this.name       = name;
    this.data       = data;
    this.hidden     = false
    this.state      = WebRocket.SubscriptionState.UNSUBSCRIBED;
    this.events     = new WebRocket.Events;
    this.members    = [];
    
    var getType = function() {
        switch(true) {
        case !!this.name.match('^presence-'):
            return 'presence';
            break;
        case !!this.name.match('^private-'):
            return 'private';
            break;
        default:
            return 'normal';
            break;
        }
    };

    this.type = getType();
};

WebRocket.Channel.prototype = {
    constructor: WebRocket.Channel,

    isSubscribed: function() {
        return this.state == WebRocket.SubscriptionState.SUBSCRIBED;
    },

    isSubscribing: function() {
        return this.state == WebRocket.SubscriptionState.SUBSCRIBING || this.isSubscribed();
    },

    subscribe: function(data, hidden) {
        if (this.isSubscribed()) return false;
        var payload = { subscribe: { channel: this.name, data: data } };
        if (!!hidden) payload['hidden'] = true;
        this.data = data;
        this.hidden = !!hidden;
        this.state = WebRocket.SubscriptionState.SUBSCRIBING;
        this.connection.send(payload);
    },

    unsubscribe: function(data) {
        if (!this.isSubscribed()) return false;
        var payload = { unsubscribe: { channel: this.name, data: data } };
        this.state = WebRocket.SubscriptionState.UNSUBSCRIBING;
        this.connection.send(payload);
    },

    broadcast: function(event, data, trigger) {
        var payload = { broadcast: { channel: this.name, event: event, data: data } };
        if (trigger) payload['trigger'] = true;
        return this.connection.send(payload);
    },

    bind: function(event, fn) {
        return this.events.bind(event, fn);
    },

    unbind: function(event) {
        return this.events.unbind(event);
    },
    
    trigger: function(event, data) {
        this.events.trigger(event, data);
    },

    subscription: function(yesno) {
        if (yesno) {
            this.events.state = WebRocket.SubscriptionState.SUBSCRIBED;
        } else {
            this.members = [];
            this.events.state = WebRocket.SubscriptionState.UNSUBSCRIBED;
        }
    },

    addMember: function(data) {
        this.members[data.uid] = data;
    },

    delMember: function(data) {
        delete(this.members[data.uid]);
    }
}

WebRocket.Error = function WebRocketError(status, code) {
    this.status = status;
    this.code   = code;
};

//if(typeof module != 'undefined') module.exports = WebRocket;
