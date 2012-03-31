// Main WebRocket object.
//
// url     - The String URL of the WebRocket server.
// options - The Object with custom options:
//           debug: The Bool saying whether debug mode is enabled or not
//           authURL: The String URL of the authentication service
//
// Examples:
//
//     var wr = new WebRocket('ws://localhost:8080/test');
//     wr.authenticate();
//     var helloChan = wr.subscribe('helloChan');
//     helloChan.bind('hello', function(data) {
//         alert('Hello from ' + data.who);
//     });
//
var WebRocket = function(url, options) {
    this.connection = new WebRocket.Connection(url, options)
};

// WebRocket methods.
WebRocket.prototype = {
    constructor: WebRocket,

    // Binds callback to specified event.
    //
    // event - The String name of the event.
    // fn    - The Function callback to be bound.
    //
    bind: function(event, fn) {
        return this.connection.bind(event, fn);
    },

    // Removes all bindings from specified event.
    //
    // event - The string name of the event.
    //
    unbind: function(event) {
        return this.connection.unbind(event);
    },

    // Broadcasts event to specified channel. If trigger specified,
    // then asynchronously triggers specified background operation.
    //
    // channel - The String channel name to broadcast on.
    // event   - The String evnent name to be broadcasted.
    // data    - The Object data attached to the event.
    // trigger - The String name of the backend operation.
    //
    // Examples
    //
    //     wr.broadcast('world', 'hello', { who: 'Bruno' });
    //     wr.broadcast('room', 'message', { text: 'Hello!' }, 'store_history');
    //
    broadcast: function(channel, event, data, trigger) {
        return this.connection.broadcast(channel, event, data, trigger);
    },

    // Schedules execution of backend operation.
    //
    // event - The String name of backend event to be executed.
    // data  - The Object data attached to the event.
    //
    trigger: function(event, data) {
        return this.connection.trigger(event, data);
    },

    // Subscribes channel.
    //
    // channel - The String channel name to be subscribed.
    // data    - The Object data attached to subscription (presence channel only)
    // hidden  - The Bool whether subscription is hidden or public (presence
    //           channel only).
    //
    // Examples:
    //
    //    var worldChan = wr.subscribe('world');
    //    worldChan.broadcast('hello', { who: 'Bruno' });
    //
    subscribe: function(channel, data, hidden) {
        return this.connection.subscribe(channel, data, hidden);
    },

    // Unsubscribes channel.
    //
    // channel - The String channel name to be unsubscribed.
    // data    - The Object data attached to unsubscription (presence channel
    //           only).
    //
    unsubscribe: function(channel, data) {
        return this.connection.unsubscribe(channel, data);
    },

    // Authenticate session. Required for private and presence channels,
    // and to be able to trigger background operations.
    //
    // options - The Object extra parameters to be passed to authentication
    //           request.
    //
    authenticate: function(options) {
        return this.connection.authenticate(options);
    },

    // Closes connection.
    //
    // data - The Object extra data attached to close command.
    //
    close: function(data) {
        return this.connection.close(data);
    },

    // Connects to the server.
    connect: function() {
        return this.connection.connect();
    },
    
    // Force reconnects to the server.
    reconnect: function() {
        this.connection.retries = 1;
        return this.connection.reconnect();
    }
};

// Possible connection states.
WebRocket.ConnectionState = {
    NOT_CONNECTED:  1,
    CONNECTING:     2,
    AUTHENTICATING: 4,
    CONNECTED:      4,
    CLOSING:        8,
    CLOSED:         16,
    BROKEN:         32
};

// WebRocket connections manages connection state and configuration.
//
// url     - The String URL to websockets server.
// options - The Object with connection options.
//
WebRocket.Connection = function WebRocketConnection(url, options) {
    options         = !!options ? options : {};
    this.url        = url;
    this.debug      = !!options.debug;
    this.maxRetries = !!options.maxRetries ? options.maxRetries : 3;
    this.authurl    = !!options.authURL ? options.authURL : '/webrocket/auth.json';
    this.state      = WebRocket.ConnectionState.NOT_CONNECTED;
    this.socket     = undefined;
    this.channels   = new WebRocket.Channels(this);
    this.events     = new WebRocket.Events;
    this.auths      = [];
    this.retries    = 1
};

// WebRocket Connection methods.
WebRocket.Connection.prototype = {
    constructor: WebRocket.Connection,

    // Returns object parsed from JSON data.
    //
    // data - The String JSON data to be parsed.
    //
    __unpack: function(data) {
        return JSON.parse(data);
    },

    // WebSocket onopen callback.
    __onopen: function(event) {
        this.state = WebRocket.ConnectionState.CONNECTING;
        this.retries = 1;

        if (this.debug) {
            console.log("D: WebRocket: Connecting");
        }
    },

    // WebSocket onclose callback.
    __onclose: function(event) {
        console.log("WebRocket: Unexpectedly closed connection");
        if (!this.isBroken()) {
            this.state  = WebRocket.ConnectionState.NOT_CONNECTED;
            this.reconnect();
        }
    },

    // WebSocket onmessage callback.
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

    // WebSocket onerror callback.
    __onerror: function(event) {
        // We're not fucking around. Reconnecting!
        console.log("WebRocket: Connection error", event);
        this.state  = WebRocket.ConnectionState.BROKEN;
        this.reconnect();
    },

    // Performs authentication request.
    __authenticate: function(options) {
        // TODO: change it to work withut jQuery
        if (this.debug) {
            console.log("D: WebRocket: Authenticating");
        }

        var self = this;
        var params = "";
        if (!!options) {
            for (var param in options) {
                params += param + '=' + options[param] + '&';
            }
        }

        var requestUrl = this.authurl + "?" + params;
        var request = new XMLHttpRequest();
        if (!request) return false;

        request.open("GET", requestUrl, true);
        request.onreadystatechange = function() {
            if (request.readyState != 4) return
            if (request.status != 200 && request.status != 304) {
                // TODO: better errors handling!
                console.log("WebRocket: Authentication error");
            }
            var data = self.__unpack(request.responseText);
            if (data.token) {
                payload = { auth: { token: data.token } };
                self.send(payload);
            }
        }
        request.send();
    },
    
    // Returns whether socket is connected or not.
    isConnected: function() {
        return this.state == WebRocket.ConnectionState.CONNECTED;
    },

    // Returns whether socket is broken or not.
    isBroken: function() {
        return this.state == WebRocket.ConnectionState.BROKEN;
    },
    
    // Sends given payload to the server.
    //
    // data - The Object payload to be sent.
    //
    send: function(data) {
        if (!this.isConnected()) {
            console.log("WebRocket: Not connected");
            return false;
        }
        var payload = JSON.stringify(data);
        if (this.debug) {
            console.log("D: WebRocket: Sending message " + payload);
        }
        return this.socket.send(payload);
    },
    
    // Connects to the server.
    connect: function() {
        var self = this;
        try {
            this.socket = new WebSocket(this.url);
        } catch(e) {}
        this.socket.onopen = function(e) { self.__onopen(e) };
        this.socket.onclose = function(e) { self.__onclose(e) };
        this.socket.onmessage = function(e) { self.__onmessage(e) };
        this.socket.onerror = function(e) { self.__onerror(e) };
    },

    // Reconnects to the server.
    reconnect: function() {
        if (this.retries < this.maxRetries) {
            this.retries += 1;
            this.connect();
        } else {
            this.events.trigger('disconnected');
        }
    },
    
    // Performs authentication.
    //
    // options - The Object extra auth parameters.
    //
    authenticate: function(options) {
        this.auths.push(options);
        if (this.isConnected()) {
            this.__authenticate(options);
        }
    },

    // Reauthenticates after reconnecect.
    reauthenticate: function() {
        for (var i = 0; i < this.auths.length; i++) {
            this.__authenticate(this.auths[i]);
        }
    },

    // Broadcasts event to specified channel. If trigger specified,
    // then asynchronously triggers specified background operation.
    //
    // channel - The String channel name to broadcast on.
    // event   - The String evnent name to be broadcasted.
    // data    - The Object data attached to the event.
    // trigger - The String name of the backend operation.
    //
    broadcast: function(channel, event, data, trigger) {
        var channel = this.channels.get(data.channel);
        if (!channel) return false
        return channel.broadcast(event, data, trigger);
    },

    // Schedules execution of backend operation.
    //
    // event - The String name of backend event to be executed.
    // data  - The Object data attached to the event.
    //
    trigger: function(event, data) {
        payload = { trigger: { event: event, data: data } };
        return this.send(payload);
    },
    
    // Subscribes channel.
    //
    // channel - The String channel name to be subscribed.
    // data    - The Object data attached to subscription (presence channel only)
    // hidden  - The Bool whether subscription is hidden or public (presence
    //           channel only).
    //
    // Examples:
    //
    //    var worldChan = wr.subscribe('world');
    //    worldChan.broadcast('hello', { who: 'Bruno' });
    //
    subscribe: function(channelName, data, hidden) {
        var channel = this.channels.get(channelName);
        if (!channel) channel = this.channels.add(channelName);
        channel.subscribe(data, hidden);
        return channel
    },

    // Unsubscribes channel.
    //
    // channel - The String channel name to be unsubscribed.
    // data    - The Object data attached to unsubscription (presence channel
    //           only).
    //
    unsubscribe: function(channelName, data) {
        var channel = this.channels.get(channelName);
        if (!channel) return false
        channel.unsubscribe(data);
        return channel
    },

    // Closes connection.
    //
    // data - The Object extra data attached to close command.
    //
    close: function(data) {
        this.state = WebRocket.ConnectionState.CLOSING;
        // TODO: ...
    },

    // Binds callback to specified event.
    //
    // event - The String name of the event.
    // fn    - The Function callback to be bound.
    //
    bind: function(event, fn) {
        return this.events.bind(event, fn);
    },

    // Removes all bindings from specified event.
    //
    // event - The string name of the event.
    //
    unbind: function(event) {
        return this.events.unbind(event);
    },

    // Protocol related callbacks...
    
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

// Events is a collection of registered events.
WebRocket.Events = function WebRocketEvents() {
    this.callbacks = {};
};

// Events methods.
WebRocket.Events.prototype = {
    constructor: WebRocket.Events,

    // Binds callback to specified event.
    //
    // event - The String name of the event.
    // fn    - The Function callback to be bound.
    //
    bind: function(event, fn) {
        var callbacks = this.callbacks[event];
        if (!callbacks) this.callbacks[event] = [];
        this.callbacks[event].push(fn);
        return fn;
    },

    // Removes all bindings from specified event.
    //
    // event - The string name of the event.
    //
    unbind: function(event) {
        delete(this.callbacks[event]);
    },

    // Calls specified event.
    //
    // event - The String local event name to be called.
    // data  - The Object parameters to be passed.
    //
    trigger: function(event, data) {
        var callbacks = this.callbacks[event];
        if (callbacks) {
            for (var i = 0; i < callbacks.length; i++) {
                callbacks[i].call({}, data);
            }
        }
    }
};

// Possible subscription states.
WebRocket.SubscriptionState = {
    UNSUBSCRIBED:  1,
    SUBSCRIBING:   2,
    SUBSCRIBED:    4,
    UNSUBSCRIBING: 8
};

// Channels is a collection of the channels.
//
// connection - The WebRocket.Connection parent connection.
//
WebRocket.Channels = function WebRocketChannels(connection) {
    this.connection = connection;
    this.channels   = {};
};

// Channels methods.
WebRocket.Channels.prototype = {
    constructor: WebRocket.Channels,

    // Registers new channel.
    //
    // name - The String name of the channel.
    //
    add: function(name) {
        var channel = this.get(name);
        if (channel) return channel;
        channel = new WebRocket.Channel(this.connection, name);
        this.channels[name] = channel;
        return channel;
    },

    // Removes specified channel.
    //
    // name - The String name of the channel.
    //
    del: function(name) {
        var channel = this.get(name);
        if (!channel) return false;
        delete(this.channels[name]);
        return true;
    },

    // Returns specified channel if exists.
    //
    // name - The String name of the channel.
    //
    get: function(name) {
        return this.channels[name];
    },

    // Iterates over all the channels.
    each: function(fn) {
        for (var channel in this.channels)
            fn(this.channels[channel]);
    },

    // Subscribes all the channels.
    subscribeAll: function() {
        this.each(function(channel) {
            if (channel.isSubscribing()) {
                channel.subscribe(channel.data, channel.hidden);
            }
        });
    },

    // Literally unsubscribes all the channels. 
    unsubscribeAll: function(data) {
        this.each(function(channel) {
            channel.unsubscribe(data);
        });
    },

    // Marks all the channels as unsubscribed.
    unmarkAll: function(data) {
        this.each(function(channel) {
            channel.subscription(false);
        })
    }
};

// Channel represents single WebRocket channel.
//
// connection - The WebRocket.Connection parent connection.
// name       - The String name of the channel.
// data       - The Object subscription data attached to the channel
//              (presence channels only).
//
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

// Channel methods.
WebRocket.Channel.prototype = {
    constructor: WebRocket.Channel,

    // Returns whether this channel is subscribed or not.
    isSubscribed: function() {
        return this.state == WebRocket.SubscriptionState.SUBSCRIBED;
    },

    // Returns whether try to subscribe this channel or not.
    isSubscribing: function() {
        return this.state == WebRocket.SubscriptionState.SUBSCRIBING || this.isSubscribed();
    },

    // Subscribes channel.
    //
    // data    - The Object data attached to subscription (presence channel only)
    // hidden  - The Bool whether subscription is hidden or public (presence
    //           channel only).
    //
    subscribe: function(data, hidden) {
        if (this.isSubscribed()) return false;
        var payload = { subscribe: { channel: this.name, data: data } };
        if (!!hidden) payload['hidden'] = true;
        this.data = data;
        this.hidden = !!hidden;
        this.state = WebRocket.SubscriptionState.SUBSCRIBING;
        this.connection.send(payload);
    },

    // Unsubscribes channel.
    //
    // data    - The Object data attached to unsubscription (presence channel
    //           only).
    //
    unsubscribe: function(data) {
        if (!this.isSubscribed()) return false;
        var payload = { unsubscribe: { channel: this.name, data: data } };
        this.state = WebRocket.SubscriptionState.UNSUBSCRIBING;
        this.connection.send(payload);
    },

    // Broadcasts event on the channel. If trigger specified, then
    // asynchronously triggers specified background operation.
    //
    // event   - The String evnent name to be broadcasted.
    // data    - The Object data attached to the event.
    // trigger - The String name of the backend operation.
    //
    // Examples
    //
    //     chan = wr.subscibe('world');
    //     chan.broadcast('hello', { who: 'Bruno' });
    //     chan.broadcast('message', { text: 'Hello!' }, 'store_history');
    //
    broadcast: function(event, data, trigger) {
        var payload = { broadcast: { channel: this.name, event: event, data: data } };
        if (trigger) payload['trigger'] = true;
        return this.connection.send(payload);
    },

    // Binds callback to specified event.
    //
    // event - The String name of the event.
    // fn    - The Function callback to be bound.
    //
    bind: function(event, fn) {
        return this.events.bind(event, fn);
    },

    // Removes all bindings from specified event.
    //
    // event - The string name of the event.
    //
    unbind: function(event) {
        return this.events.unbind(event);
    },

    // Confusing! This trigger runs event bound to this channel using bind
    // function.
    //
    // event - The String local event name to be called.
    // data  - The Object parameters to be passed.
    //
    trigger: function(event, data) {
        return this.events.trigger(event, data);
    },

    // Helper for setting subscription state to subscribed or unsubscribed.
    //
    // yesno - The Bool whether channel is subscribed or not.
    //
    subscription: function(yesno) {
        if (yesno) {
            this.events.state = WebRocket.SubscriptionState.SUBSCRIBED;
        } else {
            this.members = [];
            this.events.state = WebRocket.SubscriptionState.UNSUBSCRIBED;
        }
    },

    // Registers new subscriber.
    //
    // data - The Object data associated with subscriber.
    //
    addMember: function(data) {
        this.members[data.uid] = data;
    },

    // Deletes memeber from the channel.
    //
    // data - The Object data associated with subscriber.
    //
    delMember: function(data) {
        delete(this.members[data.uid]);
    }
}

// WebRocket error representation.
WebRocket.Error = function WebRocketError(status, code) {
    this.status = status;
    this.code   = code;
};

if(typeof module != 'undefined') module.exports = WebRocket;
