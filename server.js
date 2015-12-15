/*
 *       ::::::::  :::            :::      ::::::::   ::::::::
 *     :+:    :+: :+:          :+: :+:   :+:    :+: :+:    :+:
 *    +:+        +:+         +:+   +:+  +:+        +:+
 *   +#+        +#+        +#++:++#++: +#++:++#++ +#++:++#++
 *  +#+        +#+        +#+     +#+        +#+        +#+
 * #+#    #+# #+#        #+#     #+# #+#    #+# #+#    #+#
 * ########  ########## ###     ###  ########   ########
 */
Game = function(io, width, height) {
    this.io = io;
    this.width = width || (1 << 17) + 1;
    this.height = height || (1 << 17) + 1;
    this.players = [];
};

Game.Player = function(game, socket, color, name) {
    this.g = game;
    this.socket = socket;
    this.color = color || random_color_string();
    this.name = name || 'Generic Name (aka Bob, aka Robert)';

    this.randomizePosition();
    /*
     * socket.on('clientConnected', function (data) {
     *     console.log("new connection:", data);
     * });
     *
     * socket.on('news', function (data) {
     *     console.log(data);
     *     socket.emit('my other event', { my: 'data' });
     * });
     */
};

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
    serialize: function() {
        var players = []

        for (var i = 0; i < this.players.length; i++)
            if (this.players[i])
                players.push(this.players[i].serialize());

        return { w: this.width, h: this.height, p: players };
    },
    connectPlayer: function(socket) {
        /* Find the next available player slot */
        for (var i = 0; this.players[i]; i++)
            ;

        this.players[i] = new Game.Player(this, socket);
        this.players[i].id = i + 1;

        this.io.emit('state', this.serialize());
        socket.broadcast.emit('newPlayer', this.players[i].id);
        socket.emit('setID', this.players[i].id);

        socket.on('disconnect', (function() {
            console.log("player", this.players[i].id, "has disconnected");
            this.io.emit('playerLeft', this.players[i].id);
            this.players[i] = null;
        }).bind(this));
    }
}

Game.Player.prototype = {
    position: [0, 0], /* x/y coordinates */
    orientation: 0, /* radians */
    serialize: function() {
        return { id: this.id, pos: this.position, or: this.orientation,
            c: this.color };
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

if (typeof exports !== 'undefined') {
    if (typeof module !== 'undefined' && module.exports)
        exports = module.exports = Server;
    exports.Game = Server;
}
