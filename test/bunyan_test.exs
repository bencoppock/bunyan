defmodule BunyanTest do
  # From the io_capture docs: "when capturing something other than
  # :stdio, the test should run with async false"
  use ExUnit.Case, async: false
  use Plug.Test

  import ExUnit.CaptureIO
  require Logger

  @timestamp_pattern ~r/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6}\z/

  defp log_with_bunyan(message, opts \\ []) do
    data = capture_io(:user, fn ->
      Bunyan.info(message, opts)
      Logger.flush
    end)

    remove_extra_characters(data)
  end

  defmodule TestPlug do
    use Plug.Builder
    plug Plug.RequestId
  end

  defp log_with_plug(conn, message) do
    data = capture_io(:user, fn ->
      TestPlug.call(conn, [])
      Bunyan.info(message)
      Logger.flush
    end)

    remove_extra_characters(data)
  end

  defp remove_extra_characters(message) do
    message
    |> String.trim_leading("\e[22m")
    |> String.trim_trailing("\n\e[0m")
  end

  test "includes the user message and other basic info" do
    log = log_with_bunyan("my message") |> Poison.decode!

    assert log["level"] == "info"
    assert log["logger_name"] == "Bunyan"
    assert Regex.match? @timestamp_pattern, log["timestamp"]
    assert log["message"] == "my message"
    refute Map.has_key?(log, "request_id")
  end

  test "includes automatic request_id when used with Plug.RequestId" do
    log = conn(:get, "/")
    |> log_with_plug("yeppers!")
    |> Poison.decode!

    assert log["request_id"]
  end

  test "passes custom request_id through when used with Plug.RequestId" do
    log = conn(:post, "/")
    |> put_req_header("x-request-id", "abc123-valid-request-id")
    |> log_with_plug("yeppers!")
    |> Poison.decode!

    assert log["request_id"] == "abc123-valid-request-id"
  end
end
