defmodule Mix.Tasks.Dogma do
  use Mix.Task

  @shortdoc  "Check Elixir source files for style violations"
  @moduledoc @shortdoc

  alias Dogma.Config
  alias Dogma.Reporters

  @config_file_path "config/dogma.exs"

  def run(argv), do: main(argv)

  def main(argv) do
    {dir, reporter, noerror} = argv |> parse_args
    if File.regular?(@config_file_path) do
      Mix.Tasks.Loadconfig.run([ @config_file_path])
    end
    config = Config.build

    {:ok, dispatcher} = GenEvent.start_link([])
    GenEvent.add_handler(dispatcher, reporter, [])

    dir
    |> Dogma.run(config, dispatcher)
    |> any_errors?
    |> if do
      unless noerror do
        System.halt(666)
      end
    end
  end

  def parse_args(argv) do
    switches = [format: :string, error: :boolean]
    {switches, files, []} = OptionParser.parse(argv, switches: switches)

    noerror = !Keyword.get(switches, :error, true)
    format = Keyword.get(switches, :format)
    reporter = Map.get(
      Reporters.reporters,
      format,
      Reporters.default_reporter
    )

    {List.first(files), reporter, noerror}
  end

  defp any_errors?(scripts) do
    scripts
    |> Enum.any?( &Enum.any?( &1.errors ) )
  end
end
