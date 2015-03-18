
$(document).ready(function() {
    var l = document.location;
    $("#server_addr").val(l.host);
    $("#dest_connect_tag").val("");
    test.setLogin(false);
});

var f2num = function(n, l) {
    if (typeof l == "undefined") l = 2;
    while (n.length < l) {
        n = "0" + n;
    }
    return n;
}

var log = {
    _lasttime: 0,

    add: function(message) {
        var _log = $("#log");
        var now = new Date();
        var nowtime = now.getTime();
        if (log._lasttime > 0 && nowtime - log._lasttime > 10000) { // 10s
            $("#log").append("-------------------------\n");
        }
        log._lasttime = nowtime;

        var time = f2num(now.getHours().toString())
                 + ":" + f2num(now.getMinutes().toString())
                 + ":" + f2num(now.getSeconds().toString());
        message = $("<div/>").text(message).html();
        message = message.replace("\n", "<br />\n");
        _log.append("[<strong>" + time + "</strong>] " + message + "\n");
        _log.scrollTop(_log.prop("scrollHeight"));

        return false;
    },

    add_mark: function() {
        var _log = $("#log");
        _log.append("<strong>--------<strong>\n");
        _log.scrollTop(_log.prop("scrollHeight"));
        return false;
    },

    clear: function() {
        $('#log').empty();
        return false;
    }
}

var isFunction = function(functionToCheck) {
    var getType = {};
    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
}

var test = {
    server_addr: null,
    http_entry: "welcome_api",
    http_server_addr: null,
    websocket_entry: "welcome_socket",
    websocket_server_addr: null,

    username: null,
    session_id: null,
    connect_tag: null,

    socket: null,
    msg_id: 0,
    callbacks: {}
};

test.setLogin = function(login) {
    $("#server_addr").prop("disabled", login);
    $("#input_username").prop("disabled", login);

    $("#button_login").val(login ? "Logout" : "Login")
        .unbind("click")
        .click(function() {
            return login ? test.logout() : test.login();
        });

    if (!login) {
        $("#session_id").text("none");
        $("#connect_tag").text("none");
        $("#count_value").text("[COUNT = *]");
        $("#dest_user").empty();
        $("#dest_connect_tag").empty();
        test.username = null;
        test.session_id = null;
        test.connect_tag = null;
        test.socket = null;
        test.callbacks = {};
    }
}

test.validate_res = function(res, fields) {
    var err = res["err"];
    if (typeof err !== "undefined") {
        test.setLogin(false);
        log.add("ERR: " + err.toString());
        return false;
    }

    for (var i = 0; i < fields.length; i++) {
        var field = fields[i];
        var v = res[field];
        if (typeof v === "undefined") {
            log.add("ERR: not found field \"" + field + "\" in result");
            return false;
        }
    }
    return true;
}

test.login = function() {
    if (test.session_id) {
        log.add("ALREADY LOGIN");
        return false;
    }

    var username = $("#input_username").val();
    if (username === "") {
        log.add("PLEASE ENTER username");
        return false;
    }

    test.username = username;
    test.server_addr = $("#server_addr").val();
    test.http_server_addr = "http://" + test.server_addr + "/" + test.http_entry
    test.websocket_server_addr = "ws://" + test.server_addr + "/" + test.websocket_entry

    test.setLogin(true);

    log.add_mark();
    log.add("LOGOUT");

    var data = {"username": username}
    test.http_request("user.login", data, function(res) {
        if (!test.validate_res(res, ["sid", "tag", "count"])) {
            test.setLogin(false);
            return;
        }
        test.session_id = res["sid"].toString();
        test.connect_tag = res["tag"].toString();
        log.add("GET SESSION ID: " + test.session_id);
        log.add("count = " + res["count"].toString());
        $("#session_id").text(test.session_id);
        $("#connect_tag").text(test.connect_tag);
        $("#count_value").text("[COUNT = " + res["count"].toString() + "]");

        test.connect();
        test.setLogin(true);
    });
}

test.logout = function() {
    if (test.session_id === null) {
        log.add("ALREADY LOGOUT");
        return false;
    }

    log.add_mark();
    log.add("LOGOUT");

    test.http_request("user.logout", {"sid": test.session_id}, function(res) {
        if (test.socket) {
            test.socket.close();
        }
        test.setLogin(false);
    });
}

test.count = function() {
    if (test.session_id === null) {
        log.add("PLEASE LOGIN");
        return false;
    }

    test.http_request("user.count", {"sid": test.session_id}, function(res) {
        if (!test.validate_res(res, ["count"])) return;
        log.add("count = " + res["count"].toString());
        $("#count_value").text("[COUNT = " + res["count"].toString() + "]");
    });
}

test.on_destuserchanged = function() {
    var sel = $("#dest_user")[0];
    if (sel.selectedIndex >= 0) {
        var selected = $(sel.options[sel.selectedIndex]);
        $("#dest_connect_tag").val(selected.val());
    } else {
        $("#dest_connect_tag").val("");
    }
}

test.on_allusers = function(data) {
    var users = data["users"];
    if (users) {
        var dest_user = $("#dest_user");
        dest_user.empty();
        for (var i = 0; i < users.length; ++i) {
            var user = users[i];
            var username = $("<div/>").text(user.username).html();
            dest_user.append($("<option></option>").val(user.tag).text(user.username));
        }
        dest_user.prop("selectedIndex", -1);
    }
}

test.on_adduser = function(data) {
    var dest_user = $("#dest_user");
    dest_user.append($("<option></option>").val(data.tag).text(data.username));
}

test.on_removeuser = function(data) {
    var dest_user_options = $("#dest_user > option");
    dest_user_options.each(function() {
        if ($(this).text() == data.username) {
            $(this).remove();
            test.on_destuserchanged();
            return;
        }
    });
}

test.connect = function() {
    if (test.socket !== null) {
        return log.add("ALREADY CONNECTED");
    }

    if (test.session_id === null) {
        return log.add("LOGIN FIRST");
    }

    var protocol = "quickserver-" + test.session_id;
    log.add("CONNECT WEBSOCKET with PROTOCOL: " + protocol.toString());

    var socket = new WebSocket(test.websocket_server_addr, protocol);
    socket.onopen = function() {
        log.add("WEBSOCKET CONNECTED");
    };
    socket.onerror = function(error) {
        if (error instanceof Event) {
            log.add("ERR: CONNECT FAILED");
        } else {
            log.add("ERR: " + error.toString());
        }
    };
    socket.onmessage = function(event) {
        log.add("SOCKET RECV: " + event.data.toString());
        var data = JSON.parse(event.data);
        if (data["__id"]) {
            var msgid = data["__id"].toString();
            if (typeof test.callbacks[msgid] !== "undefined") {
                var callback = test.callbacks[msgid];
                test.callbacks[msgid] = null;
                callback(data);
            }
        } else if (data["name"]) {
            var name = "on_" + data["name"].toString();
            test[name](data);
        }
    };
    socket.onclose = function() {
        log.add("WEBSOCKET DISCONNECTED");
        test.setLogin(false);
    };

    test.socket = socket;
    return false;
}

test.disconnect = function() {
    if (test.socket === null) {
        log.add("NOT CONNECTED");
    } else {
        test.socket.close();
        test.socket = null;
        test.callbacks = {};
    }
    return false;
}

test.http_request = function(action, data, callback) {
    var url = test.http_server_addr + "?action=" + action;
    $.post(url, data, callback, "json");
}

test.send_message = function(tag, message) {
    tag = tag.toString();
    if (tag === "") {
        log.add("PLEASE ENTER destination Connect Tag");
        return false;
    }

    message = message.toString();
    if (message === "") {
        log.add("PLEASE ENTER message");
        return false;
    }

    var data = {
        "action": "chat.sendmessage",
        "tag": tag,
        "message": message,
    }

    test.send_data(data);
}

test.send_data = function(data, callback) {
    if (test.socket === null) {
        log.add("NOT CONNECTED");
        return false;
    }

    test.msg_id++;
    data["__id"] = test.msg_id;
    var json_str = JSON.stringify(data);

    if (isFunction(callback)) {
        test.callbacks[test.msg_id.toString()] = callback;
    }

    test.socket.send(json_str);
    log.add("SOCKET SEND: " + json_str);
}
