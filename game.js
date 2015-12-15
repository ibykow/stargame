/*
 *       ::::::::  :::            :::      ::::::::   ::::::::
 *     :+:    :+: :+:          :+: :+:   :+:    :+: :+:    :+:
 *    +:+        +:+         +:+   +:+  +:+        +:+
 *   +#+        +#+        +#++:++#++: +#++:++#++ +#++:++#++
 *  +#+        +#+        +#+     +#+        +#+        +#+
 * #+#    #+# #+#        #+#     #+# #+#    #+# #+#    #+#
 * ########  ########## ###     ###  ########   ########
 */
Game = function(width, height) {
    this.width = width || 800; // (1 << 17) + 1;
    this.height = height || 800; // (1 << 17) + 1;
    this.players = [];
    this.changed = true;
};

Game.Player = function(game, socket, id, color, name) {
    this.g = game;
    this.socket = socket;
    this.id = id;
    this.color = color || Game.randomColorString();
    this.name = name || 'Generic Name (aka Bob, aka Robert)';
    this.randomizePosition();
    this.changed = true;

    for (var i = 0; i < 0x100; i++)
        this.keys[i] = false;
};

/*
 *       ::::::::  :::            :::      ::::::::   ::::::::
 *     :+:    :+: :+:          :+: :+:   :+:    :+: :+:    :+:
 *    +:+        +:+         +:+   +:+  +:+        +:+
 *   +#+        +#+        +#++:++#++: +#++:++#++ +#++:++#++
 *  +#+        +#+        +#+     +#+        +#+        +#+
 * #+#    #+# #+#        #+#     #+# #+#    #+# #+#    #+#
 * ########  ########## ###     ###  ########   ########
 *
 *    :::     :::     :::     :::::::::   ::::::::
 *   :+:     :+:   :+: :+:   :+:    :+: :+:    :+:
 *  +:+     +:+  +:+   +:+  +:+    +:+ +:+
 * +#+     +:+ +#++:++#++: +#++:++#:  +#++:++#++
 * +#+   +#+  +#+     +#+ +#+    +#+        +#+
 * #+#+#+#   #+#     #+# #+#    #+# #+#    #+#
 *  ###     ###     ### ###    ###  ########
 */

Game.randomColorString = function(range, base) {
    range = range || 0xFFFFFF >> 2;
    base = base || range * 3;
    return "#" + (Math.floor(Math.random() * range) + base).toString(16);
},
Game.isNumeric = function (v) {
    return !isNaN(parseFloat(v)) && isFinite(v);
}

/*
 *       :::::::::  :::::::::   :::::::: ::::::::::: ::::::::
 *      :+:    :+: :+:    :+: :+:    :+:    :+:    :+:    :+:
 *     +:+    +:+ +:+    +:+ +:+    +:+    +:+    +:+    +:+
 *    +#++:++#+  +#++:++#:  +#+    +:+    +#+    +#+    +:+
 *   +#+        +#+    +#+ +#+    +#+    +#+    +#+    +#+
 *  #+#        #+#    #+# #+#    #+#    #+#    #+#    #+#
 * ###        ###    ###  ########     ###     ########
 */
Game.prototype = {
    serialize: function () {
        var players = []

        for (var i = 0; i < this.players.length; i++)
            if (this.players[i])
                players.push(this.players[i].serialize());

        return { w: this.width, h: this.height, p: players };
    },
    patch: function (state) {
        if (state.w) {
            this.width = state.w;
            this.height = state.h;
            this.changed = true;
        }

        for (var i = 0; i < state.p.length; i++) {
            var index = state.p[i].id - 1;
            var player = this.players[index];
            if (player) {
                this.changed = this.changed ||
                    player.patch(state.players[i]);
            } else {
                this.players[index] = this.playerFromState(state.p[i]);
                this.changed = true;
            }

        }
    },
    playerFromState: function (state) {
        var p = new Game.Player(this, null, state.id, state.c, state.name);
        if (state.pos)
            p.position = state.pos;

        if (state.or)
            p.orientation = state.orientation;

        return p;
    }
}

Game.Player.prototype = {
    keys: new Array(0xFF),
    position: [0, 0], /* x/y coordinates */
    orientation: 0, /* radians */
    serialize: function() {
        return { id: this.id, pos: this.position, or: this.orientation,
            c: this.color };
    },
    patch: function(state) {
        if (state.pos.length)
            this.position = state.pos;

        if (Game.isNumeric(state.or))
            this.orientation = state.or;

        if (state.c)
            this.color = state.c;
    },
    randomizePosition: function() {
        this.position = [
            Math.floor(Math.random() * this.g.width),
            Math.floor(Math.random() * this.g.height)
        ];
    }
}

/*
 *       :::::::::: :::    ::: :::::::::   ::::::::  ::::::::: :::::::::::
 *      :+:        :+:    :+: :+:    :+: :+:    :+: :+:    :+:    :+:
 *     +:+         +:+  +:+  +:+    +:+ +:+    +:+ +:+    +:+    +:+
 *    +#++:++#     +#++:+   +#++:++#+  +#+    +:+ +#++:++#:     +#+
 *   +#+         +#+  +#+  +#+        +#+    +#+ +#+    +#+    +#+
 *  #+#        #+#    #+# #+#        #+#    #+# #+#    #+#    #+#
 * ########## ###    ### ###         ########  ###    ###    ###
 */
