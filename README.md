# Obscura

![Game screenshot](./obscura-01.gif)

A game I wrote in Elm to learn a little more about the spooky side of functional programming.

You are a ghost in a dark universe governed by math and peopled by dullards. Move around with ASDW. Drop a torch with J.

[Play it here](http://obscura.surge.sh/)

## Guiding principles
The position of the dullards is determined by simple mathematical formulas. For instance dullards might appear arranged in a semi-circle, a spiral, or a sinusoidal curve.

Nothing is random. The position and behavior of dullards is defined by pure functions. The only variable is user input.

## Running the app

### Requirements
First, make sure [Elm is installed](https://guide.elm-lang.org/install.html).
Then, install dependencies for the server: `cd ./server && npm install`.

### Start the front end
```
elm-app start
```
Runs the game in the development mode.  
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

### Start the backend
```
node server
```
This starts an Express server that listens for "Saves". In the future, this will store the game state to a database. Right now, it just logs the save request.

### Build and deploy
```
elm-app build #Build to `/dist`
./deploy.sh #Deploy `/dist` to http://obscura.surge.sh/
```

This deploy script is pretty dumb, and provides no safety against deploying a broken build, (but helps me remember how I deployed this one!)