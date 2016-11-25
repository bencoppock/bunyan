defmodule Plug.Bunyan do
  @moduledoc """
  A plug for logging JSON messages.

  This [Plug](https://github.com/elixir-lang/plug) wraps the standard
  [Elixir Logger](http://elixir-lang.org/docs/stable/logger/Logger.html)
  and automatically generates JSON log messages.

  All requests that are processed by your plug pipeline will log the following
  fields, when avaiable:
  * `level`
  * `timestamp` (UTC)
  * `request_id` (when used in conjuction with `Plug.RequestId`)
  * `method`
  * `host`
  * `path`
  * `status`
  * `logger_name`
  * `params`
  * `duration`
  * `controller` (when used in a Phoenix application)
  * `action` (when used in a Phoenix application)
  * `format` (when used in a Phoenix application)

  To avoid logging sensitive information passed in via HTTP headers or
  params, configure headers/params to be filtered within config.exs using
  the `filter_paramaters` key, e.g.:

  ```
  config :bunyan,
    filter_parameters: ["password", "ssn"]
  ```

  Parameter filtering is case insensitive and will replace filtered values with
  the string `"[FILTERED]"`.

  If you wish to log any environment variables with `Plug.Bunyan`, provide
  Bunyan config with a list of environment variables to log along with your
  desired output names.

  For example:
  ```
  config :bunyan,
    env_vars: [{"CUSTOM_ENV_VAR", "our_env_var"}]
  ```

  ...will output the value of `CUSTOM_ENV_VAR` under a JSON key of `"our_env_var"`
  """

  alias Plug.Conn
  alias Bunyan.{Params, Timestamp}

  @behaviour Plug

  require Logger

  @env_vars Application.get_env(:bunyan, :env_vars, [])

  def init(_), do: false

  @spec call(Plug.Conn.t, any) :: Plug.Conn.t
  def call(conn, _opts) do
    start = :os.timestamp

    Conn.register_before_send(conn, fn connection ->
      :ok = log(connection, start)
      connection
    end)
  end

  @spec log(Plug.Conn.t, {non_neg_integer, non_neg_integer, non_neg_integer}) :: atom
  defp log(conn, start) do
    Logger.info fn ->
      stop = :os.timestamp
      duration = :timer.now_diff(stop, start)

      %{
        "level"       => :info,
        "method"      => conn.method,
        "timestamp"   => Timestamp.format_string(stop),
        "host"        => conn.host,
        "path"        => conn.request_path,
        "status"      => conn.status |> Integer.to_string,
        "duration"    => duration |> format_duration |> List.to_string,
        "logger_name" => "Plug.Bunyan"
      }
      |> merge_request_id(Logger.metadata[:request_id])
      |> merge_params(conn)
      |> merge_phoenix_attributes(conn)
      |> merge_headers(conn)
      |> merge_env_vars
      |> Poison.encode!
    end
  end

  @spec merge_params(map, Plug.Conn.t) :: map
  defp merge_params(log, %{params: params}) when params == %{}, do: log
  defp merge_params(log, %{params: params}) do
    Map.put(log, :params, Params.filter(params))
  end

  @spec merge_headers(map, Plug.Conn.t) :: map
  defp merge_headers(log, %{req_headers: headers}) when headers == %{}, do: log
  defp merge_headers(log, %{req_headers: headers}) do
    request_headers = headers
    |> Enum.into(%{})
    |> Params.filter

    Map.put(log, :headers, request_headers)
  end

  @spec merge_phoenix_attributes(map, Plug.Conn.t) :: map
  defp merge_phoenix_attributes(log, %{
    private: %{
      phoenix_controller: controller,
      phoenix_action: action,
      phoenix_format: format
    }
  }) do
    Map.merge(log, %{"controller" => controller, "action" => action, "format" => format})
  end
  defp merge_phoenix_attributes(log, _), do: log

  @spec merge_env_vars(map) :: map
  defp merge_env_vars(log) do
    vars = Enum.reduce(@env_vars, %{}, fn({env_var, output_name}, m) ->
      Map.put(m, output_name, System.get_env(env_var))
    end)
    Map.put(log, :env_vars, vars)
  end

  @spec format_duration(non_neg_integer) :: IO.chardata
  defp format_duration(duration) when duration > 1000 do
    [duration |> div(1000) |> Integer.to_string, "ms"]
  end
  defp format_duration(duration) do
    [duration |> Integer.to_string, "µs"]
  end

  defp merge_request_id(log, nil), do: log
  defp merge_request_id(log, request_id) do
    Map.put(log, :request_id, request_id)
  end
end
