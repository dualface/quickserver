
var log = {
    add: function(message)
    {
        var now = new Date();
        $("#log").append("<li>" + "[" + now.getTime().toString() + "] " + $("<div/>").text(message).html() + "</li>");
        return false;
    },

    add_mark: function()
    {
        $("#log").append("<li>--------</li>");
        return false;
    },

    clear: function()
    {
        $('#log').empty();
        return false;
    }
}

function isFunction(functionToCheck)
{
    var getType = {};
    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
}

var test = {
    ws: null,
    server_addr: null,
    msg_id: 0,
    session_id: null,
    callbacks: {},
    username: null
};

test.connect = function(server_addr)
{
    if (test.ws !== null)
    {
        return log.add("ALREADY CONNECTED");
    }

    server_addr = server_addr.toString();
    var ws = new WebSocket(server_addr);
    ws.onopen = function()
    {
        log.add("<" + server_addr + "> CONNECTED");
    };
    ws.onerror = function(error)
    {
        if (!(error instanceof Event))
        {
            log.add("ERR: " + error.toString());
        }
    };
    ws.onmessage = function(event)
    {
        log.add("RECV: " + event.data.toString());
        var data = JSON.parse(event.data);
        if (data["_msgid"])
        {
            var msgid = data["_msgid"].toString();
            if (typeof test.callbacks[msgid] !== "undefined")
            {
                test.callbacks[msgid](data);
                test.callbacks[msgid] = null;
            }
        }
    };
    ws.onclose = function()
    {
        log.add("<" + server_addr + "> DISCONNECTED");
        test.ws = null;
        test.server_addr = null;
    };

    test.ws = ws;
    test.server_addr = server_addr
    return false;
}

test.disconnect = function()
{
    if (test.ws === null)
    {
        log.add("NOT CONNECTED");
    }
    else
    {
        test.ws.close();
        test.ws = null;
        test.server_addr = null;
        test.session_id = null;
        test.callbacks = {};
        test.username = null;
    }
    return false;
}

test.send_data = function(data, callback)
{
    if (test.ws === null)
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

    test.ws.send(json_str);
    log.add("SEND: " + json_str);
}

test.login = function(username)
{
    if (test.session_id)
    {
        log.add("ALREADY LOGIN");
        return false;
    }

    username = username.toString();
    if (username === "")
    {
        log.add("PLEASE ENTER username");
        return false;
    }

    var data = {
        "action": "user.session",
        "id": username
    }
    test.send_data(data, function(recv_data) {
        test.session_id = recv_data["session_id"].toString();
        test.username = username;
        log.add("GET SESSION ID: " + test.session_id);
    });
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
