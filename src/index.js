import './main.css';
import { Elm } from './Main.elm';

var config = require('./config.js')

Elm.Main.init({
  node: document.getElementById('root'),
  flags: config.serverUrl
});
