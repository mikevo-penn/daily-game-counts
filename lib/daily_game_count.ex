defmodule Mix.Tasks.DailyGameCount do
  alias HTTPoison
  alias Poison
  alias Contex

  use Mix.Task
  use Timex

  # TODO:
  # - Refactor to use a config file.
  # - Create function to generate URL based on league.
  # -
  # Sample request URL for NBA:
  # https://api.thescore.com/nba/events?game_date.in=2022-12-05T05:00:00.000Z,2022-12-06T05:00:00.000Z&limit=-1&rpp=-1
  # time format for request parameter is YYYY-MM-DDTHH:MM:SS.000Z,YYYY-MM-DDTHH:MM:SS.000Z
  @impl Mix.Task
  def run(args) do

    HTTPoison.start
     params = build_game_date_parameter()

     game_data = []

    # NBA
    {:ok, response_nba} = HTTPoison.get("https://api.thescore.com/nba/events?#{params}")
    data_nba = extract_game_data(response_nba.body)
    count_nba = Enum.count(data_nba)
    game_data = [data_nba | game_data]

    # NCAAB Men's
    {:ok, response_ncaab} = HTTPoison.get("https://api.thescore.com/ncaab/events?#{params}")
    data_ncaab = extract_game_data(response_ncaab.body)
    count_ncaab = Enum.count(data_ncaab)
    game_data = [data_ncaab | game_data]

    # NCAAB Women's
    {:ok, response_wcbk} = HTTPoison.get("https://api.thescore.com/wcbk/events?#{params}")
    data_wcbk = extract_game_data(response_wcbk.body)
    count_wcbk = Enum.count(data_wcbk)
    game_data = [data_wcbk | game_data]

    # NFL
#    {:ok, response_nfl} = HTTPoison.get("https://api.thescore.com/nfl/events?#{params}")
#    data_nfl = extract_game_data(response_nfl.body)
#    count_nfl = Enum.count(data_nfl)
#    game_data = [data_nfl | game_data]

    # NCAAF
#    {:ok, response_ncaaf} = HTTPoison.get("https://api.thescore.com/ncaaf/events?#{params}")
#    data_ncaaf = extract_game_data(response_ncaaf.body)
#    count_ncaaf = Enum.count(data_ncaaf)
#    game_data = [data_ncaaf | game_data]

    # NCAAF
    {:ok, response_nhl} = HTTPoison.get("https://api.thescore.com/nhl/events?#{params}")
    data_nhl = extract_game_data(response_nhl.body)
    count_nhl = Enum.count(data_nhl)
    _ = [data_nhl | game_data]

    # Normalize game counts by hour.
 #   hourly_data = [data_nba, data_ncaab, data_wcbk, data_nfl, data_ncaaf, data_nhl]
    hourly_data = [data_nba, data_ncaab, data_wcbk, data_nhl]
    graph_data = build_graph_data(hourly_data)

    # Generate graph image.
    generate_graph_svg(graph_data)

    # Stylize the game counts into a string with padding.
    count_nba_string = transform_count_to_string(count_nba)
    count_ncaab_string = transform_count_to_string(count_ncaab)
    count_wcbk_string = transform_count_to_string(count_wcbk)
#    count_nfl_string = transform_count_to_string(count_nfl)
#    count_ncaaf_string = transform_count_to_string(count_ncaaf)
    count_nhl_string = transform_count_to_string(count_nhl)

    # Sum up the games across all the leagues we are checking.
 #   count_total_games = count_nba + count_ncaab + count_wcbk + count_nfl + count_ncaaf + count_nhl
    count_total_games = count_nba + count_ncaab + count_wcbk + count_nhl    

    # Stylize the game counts across all leagues we are chekcing into a string with padding.
    total_games_string = transform_count_to_string(count_total_games)

    # Generate the message heading
    generate_message_heading(count_total_games)

    # Low tech print out the message body.
    IO.puts("[#{count_nba_string} ] - NBA Games :basketball:")
    IO.puts("[#{count_ncaab_string} ] - NCAAB Men's Games :basketball:")
    IO.puts("[#{count_wcbk_string} ] - NCAAB Women's Games :basketball:")
#    IO.puts("[#{count_nfl_string} ] - NFL Games :football:")
#    IO.puts("[#{count_ncaaf_string} ] - NCAAF Games :football:")
    IO.puts("[#{count_nhl_string} ] - NHL Games :ice_hockey_stick_and_puck:")
    IO.puts("========================")
    IO.puts("[#{total_games_string}] - Total Games")
    IO.puts("This message is now partially automated :robot_dance: , and written in Elixir :smiling_imp: using our own APIs :mindblown:")

  end

  @spec transform_count_to_string(integer) :: binary
  def transform_count_to_string(number) do
    number
    |> Integer.to_string
    |> String.pad_leading(3, " ")
  end

  def build_game_date_parameter() do
    {:ok, current_date_time} = DateTime.now("America/New_York", Tz.TimeZoneDatabase)
    to_date_time = current_date_time |> Date.add(1)

    # time format for request parameter is YYYY-MM-DDTHH:MM:SS.000Z,YYYY-MM-DDTHH:MM:SS.000Z
    string_format = "%Y-%2m-%2dT05:00:00.000Z"
    from_date = Calendar.strftime(current_date_time, string_format)
    to_date = Calendar.strftime(to_date_time, string_format)

    "game_date.in=#{from_date},#{to_date}&limit=-1&rpp=-1"
  end

  def generate_message_heading(number_of_games) do
    {day, full_day} = get_weekday_date_string()
    # {:ok, current_date_time} = DateTime.now("America/New_York", Tz.TimeZoneDatabase)
    # day = Calendar.strftime(current_date_time, "%A")
    # full_day = Calendar.strftime(current_date_time, "%m/%d/%Y")
    volume_of_games = determine_game_volume(number_of_games)

    msg = """
          :thread: #{day} - #{full_day}

          #{volume_of_games} volume of #{number_of_games} games between 10:00 am and 11:00 pm EST timeframe today!
          """

    IO.puts msg
  end

  def determine_game_volume(games) do
    cond do
      games < 101 -> "Low"
      games > 100 && games < 151 -> "Normal"
      games > 150 && games < 201 -> "High"
      games > 200 -> "Very High"
    end
  end

  def extract_game_data(game_data) do
    Poison.decode!(game_data)
    |> Enum.map(fn (el) -> el["game_date"] end)
  end

  def build_graph_data(game_data) do
    # Go over the game_data list and extract the hours from the game_date field.
    hours = game_data
    |> Enum.map(fn (el) ->
      extract_hour(el)
    end)

    # Flatten the list of lists into a single lists and dedupe by frequencies.
    flatten_hours = List.flatten(hours)
    |> Enum.frequencies_by(& &1)

    # Normalize the hours map so that we represent all 24 hours.
    normalized_hours = fill_hours_map(flatten_hours)

    # Use comprehension to go through each k, v ito a list of tuples needed by the graphing API.
    # for {k, v} <- normalized_hours, into: [], do: {"#{k}", "#{v}"}

    # Use a simple map to go through each k, v ito a list of tuples needed by the graphing API.
    normalized_hours |> Enum.map(fn {k, v} -> {k, v} end)
  end

  def extract_hour(games) do
    # Date format going in Wed, 21 Dec 2022 00:00:00 -0000
    # For each game, parse the date and conver it to EST time which is UTC-5 hours.
    games
    |> Enum.map(fn (game) ->
      {_, dt} = Timex.parse(game, "{RFC1123}")
      dt_est = DateTime.add(dt, 60 * 60 * 5 * -1, :second, Tz.TimeZoneDatabase)
      {hour, ampm} = Timex.Time.to_12hour_clock(dt_est.hour)
      # ampm_capitalized = String.upcase("#{ampm}")
      "#{hour} #{String.upcase("#{ampm}")}"

    end)
  end

  def fill_hours_map(game_hours) do
    # Create a base map will all possible hours in a day.
    # Merge the base hours with the hours we have games starting, keeping the hour that is greater than 0.
    base_hours = %{"12 AM" => 0, "1 AM" => 0, "2 AM" => 0, "3 AM" => 0, "4 AM" => 0, "5 AM" => 0, "6 AM" => 0, "7 AM" => 0, "8 AM" => 0, "9 AM" => 0, "10 AM" => 0, "11 AM" => 0, "12 PM" => 0,
    "1 PM" => 0, "2 PM" => 0, "3 PM" => 0, "4 PM" => 0, "5 PM" => 0, "6 PM" => 0, "7 PM" => 0, "8 PM" => 0, "9 PM" => 0, "10 PM" => 0, "11 PM" => 0}
    noramlized_hours = Map.merge(base_hours, game_hours, fn _k, _v1, v2 ->
      cond do
        v2 > 0 -> v2
      end
    end)

    sort_graph_data_by_am_pm_time(noramlized_hours)

  end

  def generate_graph_svg(grap_data) do
    {day, full_day} = get_weekday_date_string()

    ds = Contex.Dataset.new(grap_data, ["hour", "games\nstarting"])
    bar_chart = Contex.BarChart.new(ds)

    options = [
      data_labels: true,
      orientation: :vertical,
      colour_palette: :warm
    ]

    # plot = Contex.Plot.new(800, 400, bar_chart, options)
    plot = Contex.Plot.new(ds, Contex.BarChart, 800, 400, options)
      |> Contex.Plot.plot_options(%{legend_setting: :legend_bottom})
      |> Contex.Plot.axis_labels("", "")
      |> Contex.Plot.titles("Game Starts by Hour - #{day} - #{full_day}", "Time is in EST 12 hour format.")

      {_, svg} = Contex.Plot.to_svg(plot)

    {:ok, file} = File.open("./priv/temp-graph.svg", [:write])
    Enum.map(svg, fn (d) -> IO.binwrite(file, d) end)
    File.close(file)

    System.cmd("convert", ["svg:./priv/temp-graph.svg", "./priv/temp-graph.jpg"])
  end

  def get_weekday_date_string() do
    {:ok, current_date_time} = DateTime.now("America/New_York", Tz.TimeZoneDatabase)
    day = Calendar.strftime(current_date_time, "%A")
    full_day = Calendar.strftime(current_date_time, "%m/%d/%Y")

    {day, full_day}
  end

  # Sort the graph data by normal time sequence of 12 am, 1 am, 2 am.. 10 pm, 11 pm. This requires trickery because computers don't understand this sequence.
  def sort_graph_data_by_am_pm_time(noramlized_hours) do
    # Sort the game hours by am to pm, then numerically 1 to 12.
    semi_sorted = Enum.sort_by(noramlized_hours, &{elem(&1, 0) =~ "PM", Integer.parse(hd(String.split(elem(&1, 0), " ")))})

    # get the correct sequence starting at 12 am to 11 am.
    am_hours = Enum.slice(semi_sorted, 11, 1) ++ Enum.slice(semi_sorted, 0, 11)

    # get the correct sequence starting at 12pm to 11 pm.
    pm_hours = [List.last(semi_sorted)] ++ Enum.slice(semi_sorted, 12,11)

    # now combine am and pm hours in order.
    am_hours ++ pm_hours
  end
end
