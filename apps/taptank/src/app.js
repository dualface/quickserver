
cc.dist = function(a, b) {
    var dx = b.x - a.x;
    var dy = b.y - a.y;
    return Math.sqrt(dx * dx + dy * dy);
}

cc.radiansBetweenPoints = function(a, b) {
    return Math.atan2(a.y - b.y, b.x - a.x);
}

cc.pointAtCircle = function(origin, radius, angle) {
    return cc.p(origin.x + Math.cos(angle) * radius, origin.y - Math.sin(angle) * radius);
}

var Tank = cc.Sprite.extend({
    ctor: function(color, id) {
        this._super();

        var animationName = "Tank" + color;
        var frameName = animationName + "0001.png"
        this.initWithSpriteFrameName(frameName);

        this._animation = cc.animate(cc.animationCache.getAnimation(animationName));

        this._id = id;
        this._speed = 60;
        this._roationSpeed = 120;
        this._begin = null;
        this._dest = null;
        this._dist = null;
        this._movelen = null;
        this._destr = null;
        this._dir = null;
        this._rotateoffset = null;

        this._state = "idle";
        this._waitMessage = false;
    },

    start: function() {
        this.stop();
        this._movingAction = this.runAction(new cc.RepeatForever(this._animation));
    },

    stop: function() {
        if (this._movingAction) {
            this.stopAction(this._movingAction);
            this._movingAction = null;
        }
    },

    trymove: function(dest) {
        if (!this.isVisible()) {
            return false;
        }

        var pos = this.getPosition();
        var data = {
            cx: pos.x,
            cy: pos.y,
            cr: this.getRotation(),
            x: dest.x,
            y: dest.y
        };
        var tank = this;
        server.sendSocketMessage("battle.move", data);
    },

    _move: function(arg) {
        this.start();
        this._begin = this.getPosition();
        this._dest = cc.p(arg.x, arg.y);
        this._dist = arg.dist;
        this._movelen = arg.dist;
        this._destr = arg.destr;
        this._dir = arg.dir;
        this._rotateoffset = arg.rotateoffset;
        this._state = "rotate";
        this.setRotation(arg.rotation);
    },

    _step: function(dt) {
        if (this._state == "idle") return;

        if (this._state == "rotate") {
            var rotation = this.getRotation();
            var offset = this._roationSpeed * dt;
            if (this._dir == "right") {
                rotation += offset;
            } else {
                rotation -= offset;
            }
            this._rotateoffset -= offset;
            if (this._rotateoffset <= 0) {
                rotation = this._destr;
                this._state = "move";
            }
            this.setRotation(rotation);
        } else if (this._state == "move") {
            var radians = cc.degreesToRadians(this.getRotation());
            var pos = this.getPosition();
            var offset = this._speed * dt;
            this._dist -= offset;
            if (this._dist <= 0) {
                this._state = "idle";
                pos = cc.pointAtCircle(this._begin, this._movelen, radians);
                this.stop();
            } else {
                pos = cc.pointAtCircle(pos, offset, radians);
            }
            this.setPosition(pos);
        }
    }
})


var BattleLayer = cc.Layer.extend({
    ctor: function() {
        this._super();

        var bg = new cc.LayerColor(cc.color(0x53, 0x47, 0x41, 255));
        this.addChild(bg);

        var sid = server.getSessionId();
        var tank = new Tank("Red", sid);
        tank.setVisible(false);
        this.addChild(tank);
        this._tank = tank;

        this._tanks = {};
        this._tanks[sid] = tank;

        var self = this;

        server.onenter = function(evt) {
            var sid = evt.__sid;
            var tank = self._tanks[sid];
            if (typeof tank === "undefined") {
                tank = new Tank("Red");
                self.addChild(tank);
            }
            tank.setVisible(true);
            tank.setPosition(evt.x, evt.y);
            tank.setRotation(evt.rotation);
            self._tanks[sid] = tank;

            // send message to server, notifies others
        };

        server.onmove = function(evt) {
            var tank = self._tanks[evt.__sid];
            if (typeof tank !== "undefined") {
                tank._move(evt);
            }
        }

        server.sendSocketMessage("battle.enter");

        var listener = cc.EventListener.create({
            event: cc.EventListener.TOUCH_ONE_BY_ONE,
            swallowTouches: true,
            onTouchBegan: function (touch, event) {
                self._tank.trymove(touch.getLocation());
                return false;
            }
        });

        cc.eventManager.addListener(listener, this);
        this.scheduleUpdate();
    },

    update: function(dt) {
        for (key in this._tanks) {
            this._tanks[key]._step(dt);
        }
    }
});

var BattleScene = cc.Scene.extend({
    onEnter: function() {
        this._super();
        var layer = new BattleLayer();
        this.addChild(layer);
    }
})
