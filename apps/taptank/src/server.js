
var SERVER_ADD = document.location.host;

// modifies based on microajax
// https://code.google.com/p/microajax/
function getJSON(url, callback)
{
    this.bindFunction = function(caller, object) {
        return function() {
            return caller.apply(object, [object]);
        };
    };

    this.stateChange = function (object) {
        if (this.request.readyState == 4) {
            var json = null;
            try {
                json = JSON.parse(this.request.responseText);
            } catch (e) {
                json = null;
            }
            this.callback(json);
        }
    };

    this.getRequest = function() {
        if (window.ActiveXObject)
            return new ActiveXObject('Microsoft.XMLHTTP');
        else if (window.XMLHttpRequest)
            return new XMLHttpRequest();
        return false;
    };

    var data = arguments[2];
    var postbody = [];
    if (data) {
        for (var name in data) {
            var value = encodeURIComponent(data[name]);
            postbody.push(name + "=" + value);
        }
    }

    this.postBody = postbody.join("&");
    this.callback = callback;
    this.url = url;
    this.request = this.getRequest();

    if(this.request) {
        var req = this.request;
        req.onreadystatechange = this.bindFunction(this.stateChange, this);
        req.open("POST", url, true);
        req.setRequestHeader("X-Requested-With", "XMLHttpRequest");
        req.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        req.send(this.postBody);
    }
}

var server = {
    _httpServerAddr: "http://" + SERVER_ADD + "/api",
    _socketServerAddr: "ws://" + SERVER_ADD + "/socket",

    _username: null,
    _sessionId: null,
    _uid: null,
    _socket: null,
    _msgId: 0,
    _callbacks: {},

    getUid: function() {
        return server._uid;
    },

    validateResult: function(result, fields) {
        var err = result["err"];
        if (err !== undefined) {
            cc.log("ERR: " + err.toString());
            return false;
        }

        for (var i = 0; i < fields.length; i++) {
            var field = fields[i];
            var v = result[field];
            if (v === undefined) {
                cc.log("ERR: not found field \"" + field + "\" in resultult");
                return false;
            }
        }

        return true;
    },

    login: function(callback) {
        if (server._sessionId) {
            cc.log("ALREADY LOGIN");
            return false;
        }

        server._username = "USER" + parseInt(Math.random() * 10000000).toString();

        var data = {"username": server._username}
        server.sendHttpRequest("user.login", function(result) {
            if (!server.validateResult(result, ["sid"])) {
                return false;
            }
            server._sessionId = result["sid"].toString();
            server._uid = result["uid"].toString();
            cc.log("GET SESSION ID: " + server._sessionId);
            server.connect(callback);
        }, data);
    },

    logout: function(callback) {
        if (server._sessionId === null) {
            cc.log("ALREADY LOGOUT");
            return false;
        }

        server.sendHttpRequest("user.logout", function(result) {
            server._sessionId = null;
            cc.log("LOGOUTED");
            if (callback) {
                callback();
            }
        });
    },

    connect: function(callback) {
        var protocol = "quickserver-" + server._sessionId;
        cc.log("CONNECT WEBSOCKET with PROTOCOL: " + protocol.toString());

        var socket = new WebSocket(server._socketServerAddr, protocol);
        socket.onopen = function() {
            cc.log("WEBSOCKET CONNECTED");
            if (callback) {
                callback();
            }
        };
        socket.onerror = function(error) {
            if (error instanceof Event) {
                cc.log("ERR: CONNECT FAILED");
            } else {
                cc.log("ERR: " + error.toString());
            }
        };
        socket.onmessage = function(event) {
            cc.log("SOCKET RECV: " + event.data.toString());
            if (event.data === null) return;

            var data = JSON.parse(event.data);
            if (data["__id"] !== undefined) {
                var msgid = data["__id"].toString();
                if (server._callbacks[msgid] !== undefined)
                {
                    var msgcallback = server._callbacks[msgid];
                    server._callbacks[msgid] = null;
                    msgcallback(data);
                }
            } else {
                var evt = data["__event"];
                if (evt !== undefined) {
                    server["on" + evt](data);
                }
            }
        };
        socket.onclose = function()
        {
            cc.log("WEBSOCKET DISCONNECTED");
            server._socket = null;
        };

        server._socket = socket;
        server._callbacks = {};
    },

    disconnect: function()
    {
        if (server._socket === null)
        {
            cc.log("NOT CONNECTED");
        }
        else
        {
            server._socket.close();
            server._socket = null;
            server._callbacks = {};
        }
        return false;
    },

    sendHttpRequest: function(action, callback, data) {
        getJSON(server._httpServerAddr + "?action=" + action, callback, data);
    },

    sendSocketMessage: function(action, message, callback) {
        if (server._socket === null) {
            cc.log("NOT CONNECTED");
            return;
        }

        server._msgId++;
        if (typeof message === "undefined") {
            message = {};
        }
        message["__id"] = server._msgId;
        message["action"] = action;
        var jsonString = JSON.stringify(message);

        if (callback !== null) {
            server._callbacks[server._msgId.toString()] = callback;
        }

        server._socket.send(jsonString);
        cc.log("SOCKET SEND: " + jsonString);
    }
}
