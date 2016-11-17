defmodule Bunyan.ErrorLoggerTest do
  # From the io_capture docs: "when capturing something other than
  # :stdio, the test should run with async false"
  use ExUnit.Case, async: false
  use Plug.Test

  import ExUnit.CaptureIO
  require Logger

  @timestamp_pattern ~r/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6}\z/

  defmodule DestinedToFailPlug do
    use Plug.Builder
    use Plug.ErrorHandler

    plug Plug.RequestId
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison
    plug :fail

    defp fail(_conn, _) do
      Poison.decode!("not JSON, oops!")
    end

    defp handle_errors(conn, %{kind: _, reason: _, stack: _} = error) do
      Bunyan.ErrorLogger.log(conn, error)
      send_resp(conn, conn.status, Poison.encode!(%{errors: %{detail: "Internal server error"}}))
    end
  end

  defp log_via_failure(conn) do
    log_data = capture_io(:user, fn ->
      try do
        DestinedToFailPlug.call(conn, [])
      rescue
        _ -> Logger.flush
      end
    end)

    remove_extra_characters(log_data)
  end

  defp remove_extra_characters(message) do
    message
    |> String.trim_leading("\e[31m")
    |> String.trim_trailing("\n\e[0m")
  end

  test "logs a 500 error" do
    log = conn(:get, "/a_path") |> log_via_failure |> Poison.decode!

    assert log["level"] == "error"
    assert String.match? log["timestamp"], @timestamp_pattern
    assert String.match? log["message"], ~r(\A#{Regex.escape("** (Poison.SyntaxError) Unexpected token at position 0: n\n")})
    assert log["host"] == "www.example.com"
    assert log["path"] == "/a_path"
    assert log["method"] == "GET"
    assert log["status"] == "500"
    assert log["request_id"]
    assert log["logger_name"] == "Bunyan.ErrorLogger"
  end
end
