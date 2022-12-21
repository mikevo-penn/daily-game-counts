# DailyGameCount

**This app generates a message and visual graph depicting the volume of live games for the current day**

## What it does
This app will generate a message and visual graph depicting the live game volume for the current day.
The app uses the [Sports API Public APIs](https://github.com/scoremedia/sports) to collect game data by league.
It then does some simple summation and data parsing to generate the message intended to be posted to the slack channel [#tsm-product-ops](https://thescore.slack.com/archives/CUVKADEAU)

## Sample Message and Bar Graph.
<img width="713" alt="image" src="https://user-images.githubusercontent.com/107335238/208815041-fd539a8b-1b3c-4cd6-902f-efd2b8306f66.png">

![image](https://user-images.githubusercontent.com/107335238/208814903-67d95a58-ac36-40a8-943c-5f8286d70ad4.png)


## How it generate the message?
1. The app calls the public `events` APIs available from Sports API. The URL is `https://api.thescore.com/<league>/events?#{params}`
2. The `{params}` are:
    1. `game_date` parameter for which we specify the range separated by a comma.
    2. `limit` parameter which we set to -1 for no limit.
    3. `rpp` parameter which is set to -1 for some crazy reason.
    4. Example: `game_date.in=2022-12-05T05:00:00.000Z,2022-12-06T05:00:00.000Z&limit=-1&rpp=-1`
3. The app then sums the number of games per day for the particular league.
4. The app will then fill in the message template with the game count data.
4. The app will then attempt to generate a bar graph in SVG form using the [Contex Library](https://github.com/mindok/contex) showing when the concentration of game starts by hour using the `game_date` data for each event.
5. After the bar graph SVG is generated, we use ImageMagick to convert the graph image to a jpg.

## Installation
You can just clone the code and run it locally for now. To do this there are 3 steps.
1. Clone the repo. `git clone git@github.com:mikevo-penn/daily-game-counts.git`
2. Install the dependencies `mix get.deps`
3. Install `ImageMagick` on your local machine.

## Running the app
You can invoke the app like this: `mix DailyGameCount`

## TODO
- [x] Build basic functionality and message.
- [x] Invent a method to generate a bar graph from the game start data.
- [ ] Update bar chart to use AM / PM EST Time.
- [ ] Refactor code to use a config file to read set of leagues to generate the message for.
- [ ] Enable a runtime arg to specify days out from today.
- [ ] Containerize the app so that ImageMagick doesn't need to be installed locally.
- [ ] ...
- [ ] Profit!
