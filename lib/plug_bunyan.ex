defmodule Plug.Bunyan do
  @moduledoc """
  A plug for logging JSON.

  This [Plug](https://github.com/elixir-lang/plug) wraps the standard
  [Elixir Logger](http://elixir-lang.org/docs/stable/logger/Logger.html)
  and automatically generates JSON log messages.

  In the context of a Phoenix app, the generated log message will include
  controller, action, and format (e.g. HTML or JSON).

  To avoid logging sensitive information that's passed in via params, configure
  which parameters should be filtered within config.exs, e.g.:

  ```
  config :bunyan,
    filter_parameters: ["password", "ssn"]
  ```

  Parameter filtering is case insensitive and will replace filtered values with
  the string `"[FILTERED]"`.

  To log environment variables, add configuration by providing a list of tuples
  which specify environment variables to log along with the desired output names.

  For example:
  ```
  config :bunyan,
    env_vars: [{"CUSTOM_ENV_VAR", "our_env_var"}]
  ```

  ...will output the value of `CUSTOM_ENV_VAR` under a JSON key of `"our_env_var"`

  HTTP headers with a given prefix can be logged. To do so, add configuration
  by providing a desired header prefix to watch for. The prefix will be removed
  and hyphens will be replaced by underscores when logged.

  For example:
  ```
  config :bunyan,
    header_prefix: "x-some-prefix-"
  ```

  This example config would include any headers that begin with "x-some-prefix-"
  (case insensitive). Therefore, `"x-some-prefix-custom-header=17"` would be
  logged as `{"custom_header": "17"}`

  If used in conjunction with (and after) Plug.RequestId, this plug will log the
  x-request-id header as "request_id".
  """

  alias Plug.Conn
  alias Bunyan.Params

  @behaviour Plug

  require Logger

  @header_prefix     Application.get_env(:bunyan, :header_prefix, "")
  @env_vars          Application.get_env(:bunyan, :env_vars, [])

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
        "timestamp"   => stop |> format_timestamp |> List.to_string,
        "path"        => conn.request_path,
        "params"      => conn.params |> Params.filter,
        "status"      => conn.status |> Integer.to_string,
        "duration"    => duration |> format_duration |> List.to_string,
        "request_id"  => Logger.metadata[:request_id],
        "logger_name" => "Plug.Bunyan"
      }
      |> merge_phoenix_attributes(conn)
      |> merge_flagged_headers(@header_prefix, conn)
      |> merge_env_vars(@env_vars)
      |> Poison.encode!
    end
  end

  @spec merge_flagged_headers(map, binary, Plug.Conn.t) :: map
  defp merge_flagged_headers(log, "", _), do: log

  defp merge_flagged_headers(log, prefix, %{req_headers: request_headers}) do
    pattern = ~r/^#{Regex.escape(prefix)}/i

    request_headers
    |> Stream.filter(fn {header,_} -> Regex.match?(pattern, header) end)
    |> Stream.map(fn {hdr, val} -> {String.trim_leading(hdr, prefix), val} end)
    |> Stream.map(fn {hdr, val} -> {String.replace(hdr, "-", "_"), val} end)
    |> Enum.into(%{})
    |> Map.merge(log)
  end

  @spec merge_phoenix_attributes(map, Plug.Conn.t) :: map
  defp merge_phoenix_attributes(log, %{
    private: %{
      phoenix_controller: controller,
      phoenix_action: action,
      phoenix_format: format
    }
  }) do
    %{"controller" => controller, "action" => action, "format" => format}
    |> Map.merge(log)
  end

  defp merge_phoenix_attributes(log, _), do: log

  @spec merge_env_vars(map, list) :: map
  defp merge_env_vars(log, env_vars) do
    env_vars
    |> Enum.reduce(%{}, fn({var, key}, m) -> Map.put(m, key, System.get_env(var)) end)
    |> Map.merge(log)
  end

  @spec format_duration(non_neg_integer) :: list
  defp format_duration(duration) when duration > 1000 do
    [duration |> div(1000) |> Integer.to_string, "ms"]
  end

  defp format_duration(duration) do
    [duration |> Integer.to_string, "µs"]
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
