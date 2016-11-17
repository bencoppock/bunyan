defmodule Plug.BunyanTest do
  # From the io_capture docs: "when capturing something other than
  # :stdio, the test should run with async false"
  use ExUnit.Case, async: false
  use Plug.Test

  import ExUnit.CaptureIO
  require Logger

  @timestamp_pattern ~r/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6}\z/

  defmodule TestPlug do
    use Plug.Builder

    plug Plug.RequestId
    plug Plug.Bunyan
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      pass: ["*/*"],
      json_decoder: Poison
    plug :send_response

    defp send_response(conn, _) do
      Plug.Conn.send_resp(conn, 200, "The Response")
    end
  end

  defp log_with_plug_bunyan(conn) do
    data = capture_io(:user, fn ->
      Process.put(:connection, TestPlug.call(conn, []))
      Logger.flush
    end)

    {Process.get(:connection), remove_extra_characters(data)}
  end

  defp remove_extra_characters(message) do
    message
    |> String.trim_leading("\e[22m")
    |> String.trim_trailing("\n\e[0m")
  end

  test "correct base output" do
    {_conn, message} = conn(:get, "/the_path") |> log_with_plug_bunyan
    log = Poison.decode!(message)

    assert log["level"] == "info"
    assert Regex.match? @timestamp_pattern, log["timestamp"]
    assert log["duration"]
    assert log["params"] == %{}
    assert log["path"] == "/the_path"
    assert log["method"] == "GET"
    assert log["status"] == "200"
    assert log["request_id"]
    assert log["logger_name"] == "Plug.Bunyan"
  end

  test "includes params" do
    {_conn, message} = conn(:post, "/", %{Property: %{Address: %{City: "Duluth"}}})
    |> put_private(:phoenix_controller, "PretendController")
    |> put_private(:phoenix_action, :fake_action)
    |> put_private(:phoenix_format, "json-maybe")
    |> log_with_plug_bunyan

    log = Poison.decode!(message)

    assert log["level"] == "info"
    assert Regex.match?(@timestamp_pattern, log["timestamp"])
    assert log["duration"]
    assert log["controller"] == "PretendController"
    assert log["action"] == "fake_action"
    assert log["format"] == "json-maybe"
    assert log["path"] == "/"
    assert log["method"] == "POST"
    assert log["status"] == "200"
    assert log["params"] == %{
      "Property" => %{
        "Address" => %{
          "City" => "Duluth"
        }
      }
    }
  end

  test "includes Phoenix specific info when present" do
    {_conn, message} = conn(:get, "/", %{Property: %{Address: %{City: "Duluth"}}})
    |> put_private(:phoenix_controller, "PretendController")
    |> put_private(:phoenix_action, :fake_action)
    |> put_private(:phoenix_format, "json-maybe")
    |> log_with_plug_bunyan

    log = Poison.decode!(message)

    assert log["controller"] == "PretendController"
    assert log["action"] == "fake_action"
    assert log["format"] == "json-maybe"
  end

  test "includes request_id plus any headers with prefixes called out by config" do
    {_conn, message} = conn(:post, "/", %{property: %{address: %{city: "Duluth"}}})
    |> put_req_header("x-request-id", "abc123-valid-request-id")
    |> put_req_header("x-some-prefix-greeting", "howdy-pardner")
    |> log_with_plug_bunyan

    log = Poison.decode!(message)

    assert log["request_id"] == "abc123-valid-request-id"
    assert log["greeting"] == "howdy-pardner"
  end

  test "includes environment variables specified by config" do
    System.put_env("CUSTOM_ENV_VAR", "tranquil")
    {_conn, message} = conn(:get, "/the_path") |> log_with_plug_bunyan
    log = Poison.decode!(message)

    assert log["our_env_var"] == "tranquil"
  end

  test "filters nested params per the \"filter_keys\" configuration" do
    params = %{"user" => %{"name" => "Paul Bunyan", "password" => "pass123"}}
    {_conn, message} = conn(:post, "/", params) |> log_with_plug_bunyan
    log = Poison.decode!(message)

    assert log["params"] == %{"user" => %{"name" => "Paul Bunyan", "password" => "[FILTERED]"}}
  end
end
