module Main exposing (..)

import App exposing (..)
import Browser


main : Program String Model Msg
main =
    Browser.element
      { view = view
      , init = init
      , update = update
      , subscriptions = subscriptions
      }
