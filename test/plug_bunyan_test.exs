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
    assert log["host"] == "www.example.com"
    assert log["path"] == "/the_path"
    assert log["method"] == "GET"
    assert log["status"] == "200"
    assert log["request_id"]
    assert log["logger_name"] == "Plug.Bunyan"
    refute log["params"]
    refute log["controller"]
    refute log["action"]
    refute log["format"]
  end

  test "includes headers, filtered per the \"filter_parameters\" configuration" do
    {_conn, message} = conn(:get, "/")
    |> put_req_header("greeting", "howdy-pardner")
    |> put_req_header("say-goodbye", "hasta la vista")
    |> put_req_header("api-token", "a1b2n3jad83jflcj9af1")
    |> log_with_plug_bunyan

    log = Poison.decode!(message)

    assert log["headers"] == %{
      "greeting" => "howdy-pardner",
      "say-goodbye" => "hasta la vista",
      "api-token" => "[FILTERED]"
    }
  end

  test "includes params filtered per the \"filter_parameters\" configuration" do
    params = %{
      property: %{address: %{city: "Duluth"}},
      user: %{name: "Paul Bunyan", password: "pass123"}
    }

    {_conn, message} = conn(:post, "/", params)
    |> log_with_plug_bunyan

    log = Poison.decode!(message)

    assert log["method"] == "POST"
    assert log["params"] == %{
      "property" => %{"address" => %{"city" => "Duluth"}},
      "user" => %{"name" => "Paul Bunyan", "password" => "[FILTERED]"}
    }
  end

  test "includes Phoenix-specific info when present" do
    {_conn, message} = conn(:get, "/")
    |> put_private(:phoenix_controller, "PretendController")
    |> put_private(:phoenix_action, :fake_action)
    |> put_private(:phoenix_format, "json-maybe")
    |> log_with_plug_bunyan

    log = Poison.decode!(message)

    assert log["controller"] == "PretendController"
    assert log["action"] == "fake_action"
    assert log["format"] == "json-maybe"
  end

  test "includes request_id" do
    {_conn, message} = conn(:get, "/")
    |> put_req_header("x-request-id", "abc123-valid-request-id")
    |> log_with_plug_bunyan

    log = Poison.decode!(message)

    assert log["request_id"] == "abc123-valid-request-id"
  end

  test "includes any environment variables specified by config" do
    System.put_env("CUSTOM_ENV_VAR", "tranquil")
    {_conn, message} = conn(:get, "/the_path") |> log_with_plug_bunyan
    log = Poison.decode!(message)

    assert log["env_vars"] == %{
      "our_env_var" => "tranquil"
    }
  end
end
