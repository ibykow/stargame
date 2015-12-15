var app = require('express')();
var http = require('http').Server(app);
var io = require('socket.io')(http);
var Game = require('./lib/game').Game;
var g = new Game();
var port = 3000;
var logger = require('./logger'),
    log = logger.info,
    info = logger.info,
    elog = logger.error,
    dlog = logger.debug;
var intervals = {
    client: null
};


http.listen(port, function (err) {
    if (err)
        elog(err);
    else
        log('http server running on port', port);
});

app.get('/', function (req, res) {
    res.sendFile(__dirname + '/index.html');
});

app.get('/*', function (req, res) {
    res.sendFile(req.params[0], { root: __dirname });
});

io.on('connection', function (socket) {
    /* Find the next available player slot */
    for (var i = 0; g.players[i]; i++)
        ;

    g.players[i] = new Game.Player(g, socket, i + 1);

    info("player", g.players[i].id, "connected");

    socket.emit('init', { state: g.serialize(), id: g.players[i].id});

    socket.broadcast.emit('newPlayer', g.players[i].id);

    socket.on('disconnect', function() {
        info("player", g.players[i].id, "disconnected");
        io.emit('playerLeft', g.players[i].id);

        g.players[i] = null;
    });
});

intervals.client = setInterval(function() { io.emit('state', g.serialize()); }, 30);
