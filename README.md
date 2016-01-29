# StarGame
A Multiplayer Space Adventure

### Install

#### Clone
    $ git clone git@github.com:ibykow/stargame.git
    $ cd stargame

#### Configure
In ```coffee/config.coffee``` change ```Config.common.url``` to your address/port.

#### Install Dependencies and Run the Server
Make sure you have CoffeeScript installed:

    $ npm install -g coffee-script

Then,

    $ ./run

The ```run``` shell script installs npm dependencies, compiles the CoffeeScript and starts the application.

#### Connect
Finally, if everything has worked according to plan, point your browser to the address and port you specified in ```coffee/config.coffee``` and let the star adventure begin!

### Controls
| Action  | Key         |
|---------|-------------|
| Move    | Up, Down    |
| Turn    | Left, Right |
| Brake   | Space       |
| Fire    | F           |

### What's new?

##### 24 Jan 2016
- Added a benchmark tool.

### What's available?
* canvas rendering
* socket.io multiplayer
* basic firing and collision detection

### What's missing?
- upgrades
- missions/story/gameplay
