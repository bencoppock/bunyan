defmodule Bunyan do
  @moduledoc """
  A JSON logger.

  This module wraps the standard Elixir `Logger` and enables log messages to be
  generated in JSON format.

  If used after `Plug.RequestId`, the output will contain the connection's
  request_id.
  """

  @type message :: IO.chardata | String.Chars.t

  @levels [:error, :warn, :info, :debug]

  require Logger

  alias Bunyan.Timestamp

  @doc """
  Logs a debug message.

  Returns the atom `:ok` or an `{:error, reason}` tuple.

  ## Examples
      Bunyan.debug "--> Here! <--"
      Bunyan.debug fn -> "expensive to calculate debug" end
  """
  @spec debug(message | (() -> message), Keyword.t) :: :ok | {:error, :noproc} | {:error, term}
  def debug(chardata_or_fn, metadata \\ []) when is_list(metadata) do
    Logger.debug(json(:debug, chardata_or_fn, metadata), metadata)
  end

  @doc """
  Logs info.

  Returns the atom `:ok` or an `{:error, reason}` tuple.

  ## Examples
      Bunyan.info "It's Friday"
      Bunyan.info fn -> "expensive to calculate info" end
  """
  @spec info(message | (() -> message), Keyword.t) :: :ok | {:error, :noproc} | {:error, term}
  def info(chardata_or_fn, metadata \\ []) when is_list(metadata) do
    Logger.info(json(:info, chardata_or_fn, metadata), metadata)
  end

  @doc """
  Logs a warning message.

  Returns the atom `:ok` or an `{:error, reason}` tuple.

  ## Examples
      Bunyan.warn "Watch out!"
      Bunyan.warn fn -> "expensive to calculate warning" end
  """
  @spec warn(message | (() -> message), Keyword.t) :: :ok | {:error, :noproc} | {:error, term}
  def warn(chardata_or_fn, metadata \\ []) when is_list(metadata) do
    Logger.warn(json(:warn, chardata_or_fn, metadata), metadata)
  end

  @doc """
  Logs an error message.

  Returns the atom `:ok` or an `{:error, reason}` tuple.

  ## Examples
      Bunyan.error "Oh no!!"
      Bunyan.error fn -> "expensive to calculate error" end
  """
  @spec error(message | (() -> message), Keyword.t) :: :ok | {:error, :noproc} | {:error, term}
  def error(chardata_or_fn, metadata \\ []) when is_list(metadata) do
    Logger.error(json(:error, chardata_or_fn, metadata), metadata)
  end

  defp json(level, chardata_or_fn, _metadata) when level in @levels do
    %{
      "level"       => level,
      "timestamp"   => Timestamp.format_string(:os.timestamp),
      "logger_name" => "Bunyan",
      "message"     => chardata_or_fn |> to_message
    }
    |> merge_request_id(Logger.metadata[:request_id])
    |> Poison.encode!
  end

  defp to_message(data) when is_function(data), do: data.()
  defp to_message(data) when is_list(data) or is_binary(data), do: to_string(data)

  defp merge_request_id(log, nil), do: log
  defp merge_request_id(log, request_id) do
    Map.put(log, :request_id, request_id)
  end
end
