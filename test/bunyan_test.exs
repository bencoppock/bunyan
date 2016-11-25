defmodule BunyanTest do
  # From the io_capture docs: "when capturing something other than
  # :stdio, the test should run with async false"
  use ExUnit.Case, async: false
  use Plug.Test

  import ExUnit.CaptureIO
  require Logger

  @timestamp_pattern ~r/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6}\z/

  defp log_with_bunyan(level, message_or_function, metadata \\ []) do
    data = capture_io(:user, fn ->
      apply(Bunyan, level, [message_or_function, metadata])
      Logger.flush
    end)

    remove_extra_characters(data)
  end

  defp remove_extra_characters(message) do
    message
    |> String.trim_leading("\e[22m")
    |> String.trim_leading("\e[31m")
    |> String.trim_leading("\e[33m")
    |> String.trim_leading("\e[36m")
    |> String.trim_trailing("\n\e[0m")
  end

  test "includes the user message and other basic info" do
    log = log_with_bunyan(:info, "my message") |> Poison.decode!

    assert log["logger_name"] == "Bunyan"
    assert Regex.match? @timestamp_pattern, log["timestamp"]
    assert log["message"] == "my message"
    refute Map.has_key?(log, "request_id")
  end

  test "allows \"debug\" level" do
    log = log_with_bunyan(:debug, "my message") |> Poison.decode!
    assert log["level"] == "debug"
  end

  test "allows \"warn\" level" do
    log = log_with_bunyan(:warn, "my message") |> Poison.decode!
    assert log["level"] == "warn"
  end

  test "allows \"error\" level" do
    log = log_with_bunyan(:error, "my message") |> Poison.decode!
    assert log["level"] == "error"
  end

  test "accepts an IO List that evaluates to a message" do
    log = log_with_bunyan(:info, ["I", ["O ", "Lists"], [" love"]]) |> Poison.decode!
    assert log["message"] == "IO Lists love"
  end

  test "accepts a function that evaluates to a message" do
    log = log_with_bunyan(:info, fn -> "the message" end) |> Poison.decode!
    assert log["message"] == "the message"
  end

  defmodule TestPlug do
    use Plug.Builder
    plug Plug.RequestId
  end

  test "includes a request_id when used in a process with Plug.RequestId" do
    conn(:get, "/")
    |> TestPlug.call([])

    log = log_with_bunyan(:info, "yeppers!") |> Poison.decode!

    assert log["request_id"]
  end

  test "includes custom request_id when used in a process with Plug.RequestId" do
    conn(:post, "/")
    |> put_req_header("x-request-id", "abc123-valid-request-id")
    |> TestPlug.call([])

    log = log_with_bunyan(:info, "yeppers!") |> Poison.decode!

    assert log["request_id"] == "abc123-valid-request-id"
  end
end
