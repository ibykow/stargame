var app = require('express')(),
    http = require('http').Server(app);
    io = require('socket.io')(http),
    Server = require('./lib/server'),
    port = 3000,
    server = {},
    log = console.log;

http.listen(port, function (err) {
    if (err) {
        elog(err);
        return;
    }

    log('http server running on port', port);
});

app.get('/', function (req, res) {
    res.sendFile(__dirname + '/index.html');
});

app.get('/*', function (req, res) {
    res.sendFile(req.params[0], { root: __dirname });
});

server = new Server(io);
