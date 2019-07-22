require('./main.css')
var config = require('./config.js')
var Elm = require('./Main.elm')

var root = document.getElementById('root')

Elm.Main.embed(root, config.serverUrl)
