wsSend = function(ws, payload) {
    return ws.send(JSON.stringify(payload))
}

appendMessage = function(data) {
    text = data["message"];
    who = data["author"];
    if (who == screenName) { who = "You" }
    when = new Date(data["posted_at"]);
    entry = $($("#message_tpl").html());
    entry.find(".fn").html(who);
    entry.find(".msg").html(text);
    entry.find(".when").attr("datetime", when.toString()).html(when.getHours() + ":" + when.getMinutes());
    $("#chatlog").append(entry);
}

appendSysMessage = function(msg) {
    entry = $($("#sys_message_tpl").html());
    entry.html(msg);
    $("#chatlog").append(entry);
}

loadHistory = function() {
    return $.ajax('/room/'+roomId+'/history.json', {
        success: function(data) {
            $.each(data, function(i, entry) {
                console.log(entry);
                appendMessage(entry);
            });
        }
    });
}