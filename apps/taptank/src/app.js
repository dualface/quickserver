
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
    ctor: function(color, uid) {
        this._super();

        var animationName = "Tank" + color;
        var frameName = animationName + "0001.png"
        this.initWithSpriteFrameName(frameName);

        this._animation = cc.animate(cc.animationCache.getAnimation(animationName));

        this._uid = uid;
        this._state = "idle";
        this._speed = 60;
        this._rotationSpeed = 120;
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

    move: function(message) {
        this.start();
        this._begin = cc.p(message.x, message.y);
        this._dest = cc.p(message.destx, message.desty);
        this._dist = this._movelen = message.dist;
        this._destr = message.destr;
        this._dir = message.dir;
        this._rotateoffset = message.rotateoffset;
        this._state = "rotate";

        this.setPosition(message.x, message.y);
        this.setRotation(message.rotation);
    },

    step: function(dt) {
        if (this._state == "idle") return;

        if (this._state == "rotate") {
            var rotation = this.getRotation();
            var offset = this._rotationSpeed * dt;
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

        this._tanks = {};

        var self = this;
        var currentUid = server.getUid();

        server.onenter = function(message) {
            var uid = message.__uid;
            var tank = self._tanks[uid];
            if (typeof tank === "undefined") {
                tank = new Tank(message.color, uid);
                self.addChild(tank);
                if (currentUid == uid) {
                    cc.log("your tank %s enter battle", uid);
                    self._tank = tank;
                } else {
                    cc.log("tank %s enter battle", uid);
                }
            }
            tank.setVisible(true);
            tank.setPosition(message.x, message.y);
            tank.setRotation(message.rotation);
            self._tanks[uid] = tank;
        };

        server.onmove = function(message) {
            var uid = message.__uid;
            var tank = self._tanks[uid];
            if (typeof tank !== "undefined") {
                tank.move(message);
            }
        }

        server.onremove = function(message) {
            var uid = message.__uid;
            var tank = self._tanks[uid];
            if (typeof tank !== "undefined") {
                tank.removeFromParent();
                self._tanks[uid] = null;
            }
        }

        server.sendSocketMessage("battle.enter");

        var listener = cc.EventListener.create({
            event: cc.EventListener.TOUCH_ONE_BY_ONE,
            swallowTouches: true,
            onTouchBegan: function (touch, event) {
                self.move(touch.getLocation());
                return false;
            }
        });

        cc.eventManager.addListener(listener, this);
        this.scheduleUpdate();
    },

    move: function(dest) {
        var tank = this._tank;
        if (tank && tank.isVisible()) {
            var pos = tank.getPosition();
            var data = {
                x: pos.x,
                y: pos.y,
                rotation: tank.getRotation(),
                destx: dest.x,
                desty: dest.y
            };
            server.sendSocketMessage("battle.move", data);
        }
    },

    update: function(dt) {
        var tanks = this._tanks;
        for (uid in tanks) {
            var tank = tanks[uid];
            if (tank && tank.step) {
                tank.step(dt);
            }
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
