defmodule Bunyan.ErrorLogger do
  @moduledoc """
  An error logger.

  In your plug pipeline (e.g. router.ex in a phoenix project):
  * Add `require Logger`
  * Add `use Plug.ErrorHandler`
  * Add the following function:

  ```
  defp handle_errors(conn, %{kind: _, reason: _, stack: _} = metadata) do
    Bunyan.ErrorLogger.log(conn, metadata)
    send_resp(conn, conn.status, Poison.encode!(%{errors: %{detail: "Internal server error"}}))
  end
  ```
  """

  alias Bunyan.Timestamp

  require Logger

  def log(conn, %{kind: kind, reason: reason, stack: stacktrace}) do
    Logger.error fn ->
      %{
        "level"       => "error",
        "timestamp"   => Timestamp.format_string(:os.timestamp),
        "request_id"  => Logger.metadata[:request_id],
        "method"      => conn.method,
        "host"        => conn.host,
        "path"        => conn.request_path,
        "status"      => conn.status |> Integer.to_string,
        "message"     => Exception.format(kind, reason, stacktrace),
        "logger_name" => "Bunyan.ErrorLogger"
      }
      |> Poison.encode!
    end
  end
end
