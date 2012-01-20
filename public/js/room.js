var $newMessage = $("#new_message")
  , $newMessageText = $("#new_message_text")

$newMessage.submit(function(e) {
    wsSend(ws, {
        "trigger": {
            "event": "yodaize_and_broadcast",
            "data": {
                "channel": chanName,
                "author": screenName,
                "message": $newMessageText.val()
            }
        }
    })
    $newMessageText.val("").focus();
    e.preventDefault();
})

$newMessageText.keypress(function(e) {
    if (e.which == 13) {
        $newMessage.submit();
        e.preventDefault();
    }
})

ws.onopen = function() {
    wsSend(ws, {"auth":{"token": accessToken}})
}

ws.onmessage = function(evt) {
    data = JSON.parse(evt.data);
    
    if (data.__authenticated) {
        wsSend(ws, {"subscribe":{"channel": chanName, "data":{"name": screenName}}})
    } else if (data.__subscribed) {
    } else if (data.__memberJoined) {
        d = data.__memberJoined
        who = d.name
        if (who == screenName) { who = "You" }
        appendSysMessage(who + " joined the room");
    } else if (data.__memberLeft) {
        d = data.__memberLeft
        who = d.name
        if (who == screenName) { who = "You" }
        appendSysMessage(who + " left the room");
    } else if (data.messageSent) {
        d = data.messageSent;
        appendMessage(d);
    } else {
        console.log(evt.data)
    }
}
