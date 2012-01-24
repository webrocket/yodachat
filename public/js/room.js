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

ws.onmessage = function(evt) {
    data = JSON.parse(evt.data);
    
    if (data[":authenticated"]) {
        wsSend(ws, {"subscribe":{"channel": chanName, "data":{"name": screenName}}})
    } else if (data[":connected"]) {
        authenticate(chanName);
    } else if (data[":subscribed"]) {
    } else if (data[":memberJoined"]) {
        d = data[":memberJoined"]
        if (d.name == screenName) {
            $.when(loadHistory()).then(function() {
                appendSysMessage("You joined the room");
            })
        } else {
            appendSysMessage(d.name + " joined the room");
        }
    } else if (data[":memberLeft"]) {
        d = data[":memberLeft"]
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
