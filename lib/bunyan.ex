defmodule Bunyan do
  @moduledoc """
  A JSON logger.

  This module wraps the standard
  [Elixir Logger](http://elixir-lang.org/docs/stable/logger/Logger.html)
  and enables log messages to be generated in JSON format.

  If used after Plug.RequestId, the output will contain the connection's
  request_id.
  """

  require Logger

  @spec info(binary, list) :: atom
  def info(message, _opts \\ []) do
    Logger.info fn ->
      %{
        "level"       => "info",
        "timestamp"   => :os.timestamp |> format_timestamp |> List.to_string,
        "logger_name" => "Bunyan",
        "message"     => message
      }
      |> merge_request_id(Logger.metadata[:request_id])
      |> Poison.encode!
    end
  end

  @spec merge_request_id(map, binary) :: map
  defp merge_request_id(log, nil), do: log

  defp merge_request_id(log, request_id) do
    Map.merge(log, %{"request_id" => request_id})
  end

  @spec format_timestamp({non_neg_integer, non_neg_integer, non_neg_integer}) :: list
  defp format_timestamp({_,_,micro} = t) do
    {{year,month,day},{hour,minute,second}} = :calendar.now_to_universal_time(t)

    :io_lib.format(
      "~4w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w.~6..0w",
      [year,month,day,hour,minute,second,micro]
    )
  end
end
