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

The ```run``` shell script installs npm dependencies, "compiles" the CoffeeScript and starts the application.

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
- Hard at work adding many new bugs.
- Added a benchmark tool. Let's see if it helps.

### What's available?
* canvas rendering
* socket.io multiplayer
* basic firing and collision detection

### What's missing?
- upgrades
- missions/story/gameplay

### What's the point?
It's done for fun.

###### Player and Computer Generated Missions
The current idea is to add player *"objectives"* or **"mission fragments"** which could then be **mixed and matched to create new player experiences**. With that, the hope is to make mixing and matching the fragments so straight-forward that it would **allow non-programmers to easily create objectives, missions and stories** on their own, or have the computer generate everything on its own. That way people will be able to get a fresh and unexpected experience every time they play.
