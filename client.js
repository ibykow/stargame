 /*
  *  ####  #      # ###### #    # #####
  * #    # #      # #      ##   #   #
  * #      #      # #####  # #  #   #
  * #      #      # #      #  # #   #
  * #    # #      # #      #   ##   #
  *  ####  ###### # ###### #    #   #
  */
var client = {
    INNER_WIDTH_OFFSET: 4,
    FRAME_MS: 16,
    URI: 'http://localhost:3000',
    COLORS: {
        BACKGROUND: {
            DEFAULT: "#444"
        }
    },
    changed: true,
    g: null,
    eventHandlers: {
        keydown: function (e) {

        },
        keyup: function (e) {

        },
        mousemove: function (e) {

        },
        mousedown: function (e) {

        },
        mousedown: function (e) {

        },
        click: function (e) {

        },
        resize: function (e) {
            client.canvas.width = window.innerWidth -
                client.INNER_WIDTH_OFFSET;

            client.canvas.height = window.innerHeight -
                client.INNER_WIDTH_OFFSET;
            client.canvas.halfWidth = client.canvas.width >> 1;
            client.canvas.halfHeight = client.canvas.height >> 1;
        },
    },
    view: {
        clear: function () {
            client.c.globalAlpha = 1;
            client.c.fillStyle = client.COLORS.BACKGROUND.DEFAULT;
            client.c.fillRect(0, 0, client.canvas.width,
                client.canvas.height);
        }
    },
    update: function() {
        if (!client.state)
            return;

        client.g.patch(client.state);
        client.state = null;
        client.changed = true;
    },
    drawPlayer: function (p) {
        client.c.fillStyle = p.color;
        client.c.fillRect(p.position[0], p.position[1], 10, 10);
    },
    draw: function() {
        if (!client.changed)
            return;

        client.changed = false;

        client.view.clear();

        for (var i = 0; i < client.g.players.length; i++)
            client.drawPlayer(client.g.players[i]);
    },
    init: function(c) {
        /* Initialize the canvas */
        client.canvas = c;

        client.canvas.style.padding = 0;
        client.canvas.style.margin = 0;
        client.canvas.style.left = (client.INNER_WIDTH_OFFSET >> 1) +'px';

        client.eventHandlers.resize();

        /* Initialize the 2D context */
        client.c = canvas.getContext('2d');

        /* Create the game */
        client.g = new Game();

        /* Initialize event handlers */
        for (var k in client.eventHandlers)
            window.addEventListener(k, client.eventHandlers[k]);

        client.socket = io.connect(client.URI);

        client.socket.on('init', function (data) {
            client.state = data.state;
            client.id = data.id;
            console.log("init", data.id);
            client.frame.run(0);
        });

        client.socket.on('state', function (data) {
            client.state = data;
        });

        client.socket.on('newPlayer', function (data) {
            console.log("Player", data, "is new");
        });

        client.socket.on('playerLeft', function (data) {
            console.log("Player", data, "is has left");
            client.state[data] = null;
            client.state.p = client.state.p.filter(function (o) {
                return o.id != data
            });
        });

        client.socket.on('disconnect', function () {
            console.log("Game over!");
            client.frame.stop();
            client.socket.close();
        });
    },
    frame: {
        request: null,
        run: function (timestamp) {
            client.update();
            client.draw();

            client.frame.request =
                window.requestAnimationFrame(client.frame.run);
        },
        stop: function() {
            window.cancelAnimationFrame(client.frame.request);
        }

    }
};

/*
 *       ::::::::  ::::    ::: :::        ::::::::      :::     :::::::::
 *     :+:    :+: :+:+:   :+: :+:       :+:    :+:   :+: :+:   :+:    :+:
 *    +:+    +:+ :+:+:+  +:+ +:+       +:+    +:+  +:+   +:+  +:+    +:+
 *   +#+    +:+ +#+ +:+ +#+ +#+       +#+    +:+ +#++:++#++: +#+    +:+
 *  +#+    +#+ +#+  +#+#+# +#+       +#+    +#+ +#+     +#+ +#+    +#+
 * #+#    #+# #+#   #+#+# #+#       #+#    #+# #+#     #+# #+#    #+#
 * ########  ###    #### ########## ########  ###     ### #########
 */
window.onload = function () {
    client.init(document.querySelector('canvas'));
};

/*
 *       :::::::::  :::::::::: ::::::::   :::    ::: :::::::::: :::::::: :::::::::::
 *      :+:    :+: :+:       :+:    :+:  :+:    :+: :+:       :+:    :+:    :+:
 *     +:+    +:+ +:+       +:+    +:+  +:+    +:+ +:+       +:+           +:+
 *    +#++:++#:  +#++:++#  +#+    +:+  +#+    +:+ +#++:++#  +#++:++#++    +#+
 *   +#+    +#+ +#+       +#+    +#+  +#+    +#+ +#+              +#+    +#+
 *  #+#    #+# #+#       #+#    #+#  #+#    #+# #+#       #+#    #+#    #+#
 * ###    ### ########## ########### ########  ########## ########     ###
 *
 *       :::::::::: :::::::::      :::       :::   :::   ::::::::::
 *      :+:        :+:    :+:   :+: :+:    :+:+: :+:+:  :+:
 *     +:+        +:+    +:+  +:+   +:+  +:+ +:+:+ +:+ +:+
 *    :#::+::#   +#++:++#:  +#++:++#++: +#+  +:+  +#+ +#++:++#
 *   +#+        +#+    +#+ +#+     +#+ +#+       +#+ +#+
 *  #+#        #+#    #+# #+#     #+# #+#       #+# #+#
 * ###        ###    ### ###     ### ###       ### ##########
 */
(function() {
    var lastTime = 0;
    var vendors = ['webkit', 'moz'];
    for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame =
          window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
    }

    if (!window.requestAnimationFrame)
        window.requestAnimationFrame = function(callback, element) {
            var currTime = +new Date;
            var timeToCall = Math.max(0, client.FRAME_MS - (currTime - lastTime));
            var id = window.setTimeout(function() { callback(currTime + timeToCall); },
              timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };

    if (!window.cancelAnimationFrame)
        window.cancelAnimationFrame = function(id) {
            clearTimeout(id);
        };
}());
