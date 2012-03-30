var $newMessage = $("#new_message")
  , $newMessageText = $("#new_message_text")
  , $messageTpl = $("#message_tpl").html()
  , $sysMessageTpl = $("#sys_message_tpl").html()
  , $chatlog = $("#chatlog")
  , screenName = !!localStorage.screenName ? localStorage.screenName : ""
  , historyLoaded = false;

function newMessageSubmit(e) {
    wr.trigger("chat/yodaize_and_broadcast", {
        channel: chanName,
        author:  screenName,
        message: $newMessageText.val()
    });
    $newMessageText.val("").focus();
    e.preventDefault();
}

function newMessageTextClick(e) {
    if (e.which == 13) {
        $newMessage.submit();
        e.preventDefault();
    }
}

function promptForName() {
    while (screenName == "") {
        screenName = prompt("What's your name?");
        localStorage.screenName = screenName;
    }
}

function appendMessage(data) {
    var tpl = Handlebars.compile($messageTpl);
    d = new Date(data.posted_at);
    data.posted_at = d.getHours() + ":" + d.getMinutes();
    $chatlog.append(tpl(data));
}

function appendSysMessage(data) {
    var tpl = Handlebars.compile($sysMessageTpl);
    $chatlog.append(tpl({ message: data }));
}

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

function roomChanMemberLeft(data) {
    appendSysMessage(data.name + " left the room");
}

function roomChanMessageSent(data) {
    appendMessage(data);
}

$(document).ready(function() {
    $newMessageText.keypress(newMessageTextClick);
    $newMessage.submit(newMessageSubmit);
    promptForName();

    wr.authenticate({ channel: chanName, uid: screenName });
    
    var roomChan = wr.subscribe(chanName, { name: screenName });
    roomChan.bind(":memberJoined", roomChanMemberJoined);
    roomChan.bind(":memberLeft", roomChanMemberLeft);
    roomChan.bind("messageSent", appendMessage);
});
