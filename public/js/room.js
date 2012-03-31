var $newMessage = $("#new_message")
  , $newMessageText = $("#new_message_text")
  , $reconnectTpl = $("#reconnect_tpl").html()
  , $messageTpl = $("#message_tpl").html()
  , $sysMessageTpl = $("#sys_message_tpl").html()
  , $chatlog = $("#chatlog")
  , screenName = !!localStorage.screenName ? localStorage.screenName : ""
  , historyLoaded = false;

// Gets and broadcasts message via WebRocket's trigger mechanism.
//
// e - The Event to be performed.
//
function newMessageSubmit(e) {
    wr.trigger("chat/yodaize_and_broadcast", {
        channel: chanName,
        author:  screenName,
        message: $newMessageText.val()
    });
    $newMessageText.val("").focus();
    e.preventDefault();
}

// Adds submit on enter functionality to message text area.
//
// e - The Event to be performed.
//
function newMessageTextClick(e) {
    if (e.which == 13) {
        $newMessage.submit();
        e.preventDefault();
    }
}

// Asks user for his name. Once user specified it, it remembers
// it in the local storage.
//
// TODO: Change it to more user friendly way!
function promptForName() {
    while (screenName == "") {
        screenName = prompt("What's your name?");
        localStorage.screenName = screenName;
    }
}

// Adds message to the log.
//
// data - The Object with message information.
//
function appendMessage(data) {
    var tpl = Handlebars.compile($messageTpl);
    console.log(data.posted_at);
    d = new Date(data.posted_at);
    data.posted_at = d.getHours() + ":" + d.getMinutes();
    $chatlog.append(tpl(data));
}

// Adds system message to the log.
//
// data - The Object with message information.
//
function appendSysMessage(data) {
    var tpl = Handlebars.compile($sysMessageTpl);
    $chatlog.append(tpl({ message: data }));
}

// Loads history for the current room and updates log.
function loadHistory() {
    return $.ajax('/room/' + roomId + '/history.json', {
        success: function(data) {
            if (!!data["history"]) {
                $.each(data["history"], function(i, entry) {
                    appendMessage(entry);
                });
            }
        }
    });
}

// When current user joins the channel, then loads history and appends
// his sys message to the log, otherwise just appends sys message about
// the new subscriber.
//
// data - The Object data with subscriber information.
//
function roomChanMemberJoined(data) {
    if (!historyLoaded) {
        $.when(loadHistory()).then(function() {
            appendSysMessage(data.name + " joined the room");
            historyLoaded = true;
        });
    } else {
        appendSysMessage(data.name + " joined the room");
    }
}

// Appens system message with information about subscriber leaving the
// channel to the log.
//
// data - The Object data with subscriber information.
//
function roomChanMemberLeft(data) {
    appendSysMessage(data.name + " left the room");
}

// Callback triggered when websockets connection has been interrupted.
function onWebRocketDisconnect() {
    $chatlog.append($reconnectTpl);
}

// Reconnects with websockets server.
function reconnectClick() {
    $chatlog.html('');
    historyLoaded = false;
    wr.reconnect();
}

// Set up all the WebRocket and chat room stuff.
function setupRoom() {
    $newMessageText.keypress(newMessageTextClick);
    $newMessage.submit(newMessageSubmit);
    $('.reconnect').live('click', reconnectClick);
    
    // Authenticate for presence channel access. YES, I do know it's not
    // secure to give such params in here :). This is just dummy app to
    // present features of WebRocket and Kosmonaut so I simply don't care
    // about security :P.
    wr.authenticate({ channel: chanName, uid: screenName });

    // Handle disconnection.
    wr.bind('disconnected', onWebRocketDisconnect)
    
    // Subscribe to the channel and bind callbacks.
    var roomChan = wr.subscribe(chanName, { name: screenName });
    roomChan.bind(":memberJoined", roomChanMemberJoined);
    roomChan.bind(":memberLeft", roomChanMemberLeft);
    roomChan.bind("messageSent", appendMessage);

    // Connect with websockets.
    wr.connect();
}

// Set up all the things!
function setup() {
    if (screenName == "") {
        promptForName();
    } else {
        setupRoom();
    }
}

$(document).ready(function() {
    setup();
});
