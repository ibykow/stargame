var app = require('express')(),
    http = require('http').createServer(app),
    io = require('socket.io')(http),
    Server = require('./lib/server'),
    game = new Server(io),
    port = require('./lib/config').common.url.port;

http.listen(port, function (err) {
    if (err) {
        console.log(err);
        return;
    }

    console.log('http server running on port', port);
});

app.get('/', function (req, res) {
    res.sendFile(__dirname + '/static/index.html');
});

app.get('/css/*', function (req, res) {
    res.sendFile(req.params[0], { root: __dirname + '/static/css' });
});

app.get('/*', function (req, res) {
    res.sendFile(req.params[0], { root: __dirname });
});
