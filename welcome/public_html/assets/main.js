
$(document).ready(function()
{
    var l = document.location;
    $("#server_addr").val(l.host);
    $("#http_server_addr").text("http://" + l.host + "/");
    $("#http_entry").val("api");
    $("#websocket_server_addr").text("ws://" + l.host + "/");
    $("#websocket_entry").val("socket");
    $("#input_username").val("USER" + parseInt((Math.random() * 10000000)).toString());

    test.set_inputs_disabled(false);
});

var f2num = function(n, l)
{
    if (typeof l == "undefined") l = 2;
    while (n.length < l)
    {
        n = "0" + n;
    }
    return n;
}

var log = {
    _lasttime: 0,

    add: function(message)
    {
        var _log = $("#log");
        var now = new Date();
        var nowtime = now.getTime();
        if (log._lasttime > 0 && nowtime - log._lasttime > 10000) // 10s
        {
            $("#log").append("-------------------------\n");
        }
        log._lasttime = nowtime;

        var time = f2num(now.getHours().toString()) + ":" + f2num(now.getMinutes().toString()) + ":" + f2num(now.getSeconds().toString());
        message = $("<div/>").text(message).html();
        message = message.replace("\n", "<br />\n");
        _log.append("[<strong>" + time + "</strong>] " + message + "\n");
        _log.scrollTop(_log.prop("scrollHeight"));

        return false;
    },

    add_mark: function()
    {
        var _log = $("#log");
        _log.append("<strong>--------<strong>\n");
        _log.scrollTop(_log.prop("scrollHeight"));
        return false;
    },

    clear: function()
    {
        $('#log').empty();
        return false;
    }
}

var isFunction = function(functionToCheck)
{
    var getType = {};
    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
}

var test = {
    server_addr: null,
    http_entry: null,
    http_server_addr: null,
    websocket_entry: null,
    websocket_server_addr: null,

    username: null,
    session_id: null,

    socket: null,
    msg_id: 0,
    callbacks: {}
};

test.set_inputs_disabled = function(disabled)
{
    $("#server_addr").prop("disabled", disabled);
    $("#http_entry").prop("disabled", disabled);
    $("#websocket_entry").prop("disabled", disabled);
    $("#input_username").prop("disabled", disabled);
}

test.validate_res = function(res, fields)
{
    var err = res["err"];
    if (typeof err !== "undefined")
    {
        test.set_inputs_disabled(false);
        log.add("ERR: " + err.toString());
        return false;
    }

    for (var i = 0; i < fields.length; i++)
    {
        var field = fields[i];
        var v = res[field];
        if (typeof v === "undefined")
        {
            log.add("ERR: not found field \"" + field + "\" in result");
            return false;
        }
    }

    return true;
}

test.login = function()
{
    if (test.session_id)
    {
        log.add("ALREADY LOGIN");
        return false;
    }

    var username = $("#input_username").val();
    if (username === "")
    {
        log.add("PLEASE ENTER username");
        return false;
    }

    test.username = username;
    test.server_addr = $("#server_addr").val();
    test.http_entry = $("#http_entry").val();
    test.http_server_addr = "http://" + test.server_addr + "/" + test.http_entry
    test.websocket_entry = $("#websocket_entry").val();
    test.websocket_server_addr = "ws://" + test.server_addr + "/" + test.websocket_entry

    test.set_inputs_disabled(true);

    var data = {"username": username}
    test.http_request("hello.login", data, function(res) {
        if (!test.validate_res(res, ["sid", "count"]))
        {
            test.set_inputs_disabled(false);
            return;
        }
        test.session_id = res["sid"].toString();
        log.add("GET SESSION ID: " + test.session_id);
        log.add("count = " + res["count"].toString());
        $("#session_id").text("SESSION ID: " + test.session_id);
        $("#count_value").text("[COUNT = " + res["count"].toString() + "]");
    });
}

test.logout = function()
{
    if (test.session_id === null)
    {
        log.add("ALREADY LOGOUT");
        return false;
    }

    test.http_request("hello.logout", {"sid": test.session_id}, function(res) {
        test.session_id = null;
        log.add("LOGOUTED");
        $("#session_id").text("none");
        $("#count_value").text("[COUNT = *]");
        test.set_inputs_disabled(false);
    });
}

test.count = function()
{
    if (test.session_id === null)
    {
        log.add("PLEASE LOGIN");
        return false;
    }

    test.http_request("hello.count", {"sid": test.session_id}, function(res) {
        if (!test.validate_res(res, ["count"])) return;
        log.add("count = " + res["count"].toString());
        $("#count_value").text("[COUNT = " + res["count"].toString() + "]");
    });
}

test.connect = function()
{
    if (test.socket !== null)
    {
        return log.add("ALREADY CONNECTED");
    }

    if (test.session_id === null)
    {
        return log.add("LOGIN FIRST");
    }

    var protocol = "quickserver-" + test.session_id;
    log.add("CONNECT WEBSOCKET with PROTOCOL: " + protocol.toString());

    var socket = new WebSocket(test.websocket_server_addr, protocol);
    socket.onopen = function()
    {
        log.add("WEBSOCKET CONNECTED");
    };
    socket.onerror = function(error)
    {
        if (error instanceof Event)
        {
            log.add("ERR: CONNECT FAILED");
        }
        else
        {
            log.add("ERR: " + error.toString());
        }
    };
    socket.onmessage = function(event)
    {
        log.add("RECV: " + event.data.toString());
        var data = JSON.parse(event.data);
        if (data["_msgid"])
        {
            var msgid = data["_msgid"].toString();
            if (typeof test.callbacks[msgid] !== "undefined")
            {
                var callback = test.callbacks[msgid];
                test.callbacks[msgid] = null;
                callback(data);
            }
        }
    };
    socket.onclose = function()
    {
        log.add("WEBSOCKET DISCONNECTED");
        test.socket = null;
    };

    test.socket = socket;
    return false;
}

test.disconnect = function()
{
    if (test.socket === null)
    {
        log.add("NOT CONNECTED");
    }
    else
    {
        test.socket.close();
        test.socket = null;
        test.callbacks = {};
    }
    return false;
}

test.http_request = function(action, data, callback)
{
    var url = test.http_server_addr + "?action=" + action;
    $.post(url, data, callback, "json");
}

test.send_data = function(data, callback)
{
    if (test.socket === null)
    {
        log.add("NOT CONNECTED");
        return false;
    }

    test.msg_id++;
    data["_msgid"] = test.msg_id;
    var json_str = JSON.stringify(data);

    if (isFunction(callback))
    {
        test.callbacks[test.msg_id.toString()] = callback;
    }

    test.socket.send(json_str);
    log.add("SEND: " + json_str);
}

test.send_message = function(message)
{
    if (!test.session_id)
    {
        log.add("NOT LOGIN");
        return false;
    }

    message = message.toString();
    if (message == "")
    {
        log.add("PLEASE ENTER message");
        return false;
    }

    var data = {
        "action": "chat.broadcast",
        "session_id" : test.session_id,
        "content": message,
        "user": test.username
    }

    test.send_data(data);
}

test.call_action = function(call_action, more)
{
    if (!test.session_id)
    {
        log.add("NOT LOGIN");
        return false;
    }

    call_action = call_action.toString();
    if (call_action == "")
    {
        log.add("NOT SET action");
        return false;
    }

    var data = {
        "action": call_action,
        "session_id" : test.session_id,
        "user": test.username
    }

    if (typeof more !== "undefined")
    {
        for (var key in more)
        {
            data[key] = more[key];
        }
    }

    test.send_data(data);
}
