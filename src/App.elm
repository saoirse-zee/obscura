module App exposing (..)

import Html exposing (Html, text, div, img)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Keyboard
import Char
import AnimationFrame exposing (diffs)
import Time exposing (Time)


-- Higher -> more friction, slower movement


friction : Float
friction =
    1.01



-- Higher -> faster


boost : Float
boost =
    0.15


boundary =
    { top = 5
    , bottom = 295
    , left = 5
    , right = 595
    }


type alias Model =
    { ghost : Creature
    , dullards : List Creature
    , firefly : Creature
    , dropTime : Time
    , serverUrl : String
    }


type CreatureType
    = Ghost
    | Dullard
    | Firefly


type alias Creature =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    , obscurity : Float
    , creatureType : CreatureType
    , path : List Point
    }

type alias Pair =
    { first: Creature
    , second: Creature
    }

type alias Point =
    { x : Float
    , y : Float
    }

origin = 
    Point 0 0 

initialPath =
    [origin]

init : String -> ( Model, Cmd Msg )
init serverUrl =
    ( { ghost =
            { x = 300
            , y = 100
            , vx = 0
            , vy = -0.15
            , obscurity = 100
            , creatureType = Ghost
            , path = [Point 300 300]
            }
      , dullards = dullards
      , firefly = Creature 0 0 0 0 0 Firefly initialPath
      , dropTime = 0
      , serverUrl = serverUrl
      }
    , Cmd.none
    )


columns rows =
    let
        rowSpacing =
            50

        biggify x =
            Basics.toFloat (x * rowSpacing)
    in
        List.map biggify (List.range 1 rows)

initializeDullard : Float -> Float -> Creature
initializeDullard radius i =
    let
        velocityFactor = -0.001
        densityFactor = 100
        tau = Basics.pi * 2
        unit = tau / densityFactor 
        theta = i * unit
        x = Basics.sin theta * radius + boundary.right / 2 
        y = Basics.cos theta * radius + boundary.bottom / 2 
        vx = Basics.sin theta * velocityFactor
        vy = Basics.cos theta * velocityFactor
    in
        Creature x y vx vy 0 Dullard initialPath


dullards : List Creature
dullards =
    let 
        count = 100
        range = List.map toFloat (List.range 0 (count - 1))      
    in
        List.concat
            [   (List.map (initializeDullard 50) range) 
            ,   (List.map (initializeDullard 120) range)
            ,   (List.map (initializeDullard 130) range)
            ,   (List.map (initializeDullard 160) range)
            ,   (List.map (initializeDullard 200) range)
            ,   (List.map (initializeDullard 210) range)
            ,   (List.map (initializeDullard 220) range)
            ]

type Msg
    = KeyMsg Keyboard.KeyCode
    | Tick Time
    | ClickSave
    | HandleSaveResponse (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandleSaveResponse (Ok response) ->
            ( model, Cmd.none )

        HandleSaveResponse (Err _) ->
            ( model, Cmd.none )

        ClickSave ->
            ( model, save model )

        KeyMsg keycode ->
            case getDirection keycode of
                Left ->
                    ( { model
                        | ghost = moveLeft model.ghost
                      }
                    , Cmd.none
                    )

                Right ->
                    ( { model
                        | ghost = moveRight model.ghost
                      }
                    , Cmd.none
                    )

                Up ->
                    ( { model
                        | ghost = moveUp model.ghost
                      }
                    , Cmd.none
                    )

                Down ->
                    ( { model
                        | ghost = moveDown model.ghost
                      }
                    , Cmd.none
                    )

                DropFirefly ->
                    if model.dropTime > 5000 then
                        ( { model
                            | firefly = Creature model.ghost.x (model.ghost.y + 20) model.ghost.vx 0.1 50 Firefly initialPath
                            , dropTime = 0
                          }
                        , Cmd.none
                        )
                    else
                        ( model, Cmd.none )

                None ->
                    ( model, Cmd.none )

        Tick dt ->
            let
                ghost =
                    model.ghost
                        |> updateX dt
                        |> updateY dt
                        |> applyFriction dt
                        |> collisionCheck model.dullards
                        |> boundaryCheck
                        |> updatePowerLevel model.dropTime

                firefly =
                    model.firefly
                        |> updateY dt
                        |> updateX dt

                dullards =
                    model.dullards
                        |> List.map (obscure model.ghost model.firefly)
                        |> List.map (dullardCollisionCheck model.ghost)
                        |> List.map (updateX dt)
                        |> List.map (updateY dt)

                dropTime =
                    model.dropTime + dt
            in
                ( { model
                    | ghost = ghost
                    , dullards = dullards
                    , firefly = firefly
                    , dropTime = dropTime
                  }
                , Cmd.none
                )


updatePowerLevel : Time -> Creature -> Creature
updatePowerLevel dropTime hero =
    let
        obscurity =
            Basics.max (dropTime / 50) 60
    in
        { hero | obscurity = obscurity }


boundaryCheck : Creature -> Creature
boundaryCheck creature =
    if creature.x < boundary.left then
        { creature | vx = boost }
    else if creature.x > boundary.right then
        { creature | vx = -boost }
    else if creature.y < boundary.top then
        { creature | vy = boost }
    else if creature.y > boundary.bottom then
        { creature | vy = -boost }
    else
        creature



-- Obscure the dullards in shadow, depending on distance to ghost and firefly


obscure : Creature -> Creature -> Creature -> Creature
obscure ghost firefly dullard =
    let
        baseObscurity = 10
        obscurityDueToGhost =
            Basics.max (100 - (distance ghost dullard) ^ 1.3) baseObscurity

        obscurityDueToFirefly =
            Basics.max (100 - distance firefly dullard) baseObscurity

        obscurity =
            Basics.max obscurityDueToGhost obscurityDueToFirefly
    in
        { dullard | obscurity = obscurity }

dullardCollisionCheck : Creature -> Creature -> Creature
dullardCollisionCheck ghost dullard =
    let 
        inertia = 0.05
    in
        if distance ghost dullard < 10 then
            { dullard | vy = -ghost.vy * inertia, vx = ghost.vx * inertia } 
        else
            dullard



collisionCheck : List Creature -> Creature -> Creature
collisionCheck dullards hero =
    let
        allowableDistance = 10
        pathLength = 50
        dullard = findClosest hero dullards
        path = List.take pathLength ((Point hero.x hero.y) :: hero.path)   
    in
        if distance hero dullard < allowableDistance then
            if isAbove hero dullard then
                { hero | vy = -0.15, path = path } 
            else
                { hero | vy = 0.15, path = path }
        else
            hero


findClosest : Creature -> List Creature -> Creature
findClosest hero dullards =
    let
        closestToHero =
            closest hero

        origin =
            { hero | x = 1000, y = 1000 }
    in
        List.foldl closestToHero origin dullards



-- Find which of two creatures is nearest a target


closest : Creature -> Creature -> Creature -> Creature
closest target p1 p2 =
    if distance target p1 < distance target p2 then
        p1
    else
        p2


distance : Creature -> Creature -> Float
distance p1 p2 =
    let
        a =
            abs (p1.x - p2.x)

        b =
            abs (p1.y - p2.y)
    in
        sqrt (a * a + b * b)


isNear p1 p2 =
    (distance p1 p2) < 30


isAbove p1 p2 =
    p1.y < p2.y


updateX dt ghost =
    { ghost | x = ghost.x + ghost.vx * dt }


updateY dt ghost =
    { ghost | y = ghost.y + ghost.vy * dt }


applyFriction dt ghost =
    { ghost
        | vx = ghost.vx / friction
        , vy = ghost.vy / friction
    }


type Direction
    = Left
    | Right
    | Up
    | Down
    | DropFirefly
    | None


getDirection : Keyboard.KeyCode -> Direction
getDirection keycode =
    let
        key =
            Char.fromCode keycode
    in
        if key == 'A' then
            Left
        else if key == 'S' then
            Down
        else if key == 'D' then
            Right
        else if key == 'W' then
            Up
        else if key == 'J' then
            DropFirefly
        else
            None


moveLeft : Creature -> Creature
moveLeft creature =
    { creature | vx = creature.vx - boost }


moveRight : Creature -> Creature
moveRight creature =
    { creature | vx = creature.vx + boost }


moveUp : Creature -> Creature
moveUp creature =
    { creature | vy = creature.vy - boost }


moveDown : Creature -> Creature
moveDown creature =
    { creature | vy = creature.vy + boost }


view : Model -> Html Msg
view model =
    let
        creatures =
            model.ghost :: model.firefly :: model.dullards
    in
        div []
            [ div [ class "instructions" ] [ Html.text "Move the ghost with ASDW. Drop a firefly with J." ]
            , div []
                [ svg [ viewBox "0 0 600 300", width "1000px" ]
                    (
                        List.concat 
                            [ [viewPath model.ghost.path]
                            , (List.map viewPathPoint model.ghost.path)
                            , (List.map viewCreature creatures)
                            ]
                    )
                ]
            , div [] [ Html.button [ onClick ClickSave ] [ Html.text "Save" ] ]
            ]


viewCreature creature =
    let
        o =
            creature.obscurity / 100

        size =
            getSize creature
    in
        circle
            [ cx (toString creature.x)
            , cy (toString creature.y)
            , r (toString size)
            , class (getCreatureClass creature)  
            , opacity (toString o)
            ]
            []

viewPathPoint : Point -> Svg msg
viewPathPoint point =
        circle
            [ cx (toString point.x)
            , cy (toString point.y)
            , r (toString 1)
            , fill "white"
            ]
            []

viewCollisions : List Point -> List (Svg msg)
viewCollisions path =
    List.map viewPathPoint path
    

viewPath : List Point -> Svg msg
viewPath path =
    let 
        pts = pathToString path 
        o = 0.1
    in
        polyline 
            [ fill "none"
            , stroke "white"
            , points pts
            , opacity (toString o)
            ] []

pathToString : List Point -> String
pathToString path =
    let
        stringList = List.map pointToString path
    in
        String.concat(stringList)

pointToString : Point -> String
pointToString point =
    toString(point.x) ++ "," ++ toString(point.y) ++ " "

viewLine : Point -> Point -> Svg msg
viewLine p1 p2 = 
  line [ x1 (toString p1.x)
       , y1 (toString p1.y)
       , x2 (toString p2.x)
       , y2 (toString p2.y)
       , stroke "pink"
       ]
       []



getCreatureClass : Creature -> String
getCreatureClass creature =
  if creature.creatureType == Ghost then
    "ghost"
  else
    "dullard" 


getSize : Creature -> Int
getSize creature =
    if creature.creatureType == Ghost then
        5
    else if creature.creatureType == Firefly then
        1
    else
        3


save : Model -> Cmd Msg
save state =
    let
        url =
            state.serverUrl ++ "/save"

        ghost =
            Encode.object
                [ ( "x", Encode.float state.ghost.x )
                , ( "y", Encode.float state.ghost.y )
                ]

        body =
            Http.jsonBody ghost

        request =
            Http.post url body decodeSaveResult
    in
        Http.send HandleSaveResponse request


decodeSaveResult : Decode.Decoder String
decodeSaveResult =
    Decode.at [ "some_field" ] Decode.string


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Keyboard.downs KeyMsg
        , diffs Tick
        ]
