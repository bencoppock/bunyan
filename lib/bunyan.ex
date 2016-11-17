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

  alias Bunyan.Timestamp

  @spec info(binary, list) :: atom
  def info(message, _opts \\ []) do
    Logger.info fn ->
      %{
        "level"       => "info",
        "timestamp"   => Timestamp.format_string(:os.timestamp),
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
end
