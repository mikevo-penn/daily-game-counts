defmodule Mix.Tasks.DailyGameCount do
  alias HTTPoison
  alias Poison

  use Mix.Task

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

    # NBA
    {:ok, response_nba} = HTTPoison.get("https://api.thescore.com/nba/events?#{params}")
    data_nba = Poison.decode!(response_nba.body)
    count_nba = Enum.count(data_nba)

    # NCAAB Men's
    {:ok, response_ncaab} = HTTPoison.get("https://api.thescore.com/ncaab/events?#{params}")
    data_ncaab = Poison.decode!(response_ncaab.body)
    count_ncaab = Enum.count(data_ncaab)

    # NCAAB Women's
    {:ok, response_wcbk} = HTTPoison.get("https://api.thescore.com/wcbk/events?#{params}")
    data_wcbk = Poison.decode!(response_wcbk.body)
    count_wcbk = Enum.count(data_wcbk)

    # NFL
    {:ok, response_nfl} = HTTPoison.get("https://api.thescore.com/nfl/events?#{params}")
    data_nfl = Poison.decode!(response_nfl.body)
    count_nfl = Enum.count(data_nfl)

    # NCAAF
    {:ok, response_ncaaf} = HTTPoison.get("https://api.thescore.com/ncaaf/events?#{params}")
    data_ncaaf = Poison.decode!(response_ncaaf.body)
    count_ncaaf = Enum.count(data_ncaaf)

    # NCAAF
    {:ok, response_nhl} = HTTPoison.get("https://api.thescore.com/nhl/events?#{params}")
    data_nhl = Poison.decode!(response_nhl.body)
    count_nhl = Enum.count(data_nhl)

    # Stylize the game counts into a string with padding.
    count_nba_string = transform_count_to_string(count_nba)
    count_ncaab_string = transform_count_to_string(count_ncaab)
    count_wcbk_string = transform_count_to_string(count_wcbk)
    count_nfl_string = transform_count_to_string(count_nfl)
    count_ncaaf_string = transform_count_to_string(count_ncaaf)
    count_nhl_string = transform_count_to_string(count_nhl)

    # Sum up the games across all the leagues we are checking.
    count_total_games = count_nba + count_ncaab + count_wcbk + count_nfl + count_ncaaf + count_nhl

    # Stylize the game counts across all leagues we are chekcing into a string with padding.
    total_games_string = transform_count_to_string(count_total_games)

    # Generate the message heading
    generate_message_heading(count_total_games)

    # Low tech print out the message body.
    IO.puts("[#{count_nba_string} ] - NBA Games :basketball:")
    IO.puts("[#{count_ncaab_string} ] - NCAAB Men's Games :basketball:")
    IO.puts("[#{count_wcbk_string} ] - NCAAB Women's Games :basketball:")
    IO.puts("[#{count_nfl_string} ] - NFL Games :football:")
    IO.puts("[#{count_ncaaf_string} ] - NCAAF Games :football:")
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
    {:ok, current_date_time} = DateTime.now("America/New_York", Tz.TimeZoneDatabase)
    day = Calendar.strftime(current_date_time, "%A")
    full_day = Calendar.strftime(current_date_time, "%m/%d/%Y")
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
end
