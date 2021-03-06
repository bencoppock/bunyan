# Bunyan

  A JSON logger for Elixir.
  
  **_Note: this version of bunyan is now defunct. @pragdave separately wrote an [Elixir logging library named bunyan](https://github.com/bunyan-logger/), which is almost surely the one you're looking for!_**

  ![Paul Bunyan the Logger](/paul_bunyan.png?raw=true)

  Bunyan is a JSON logger for Elixir.

  It provides a [Plug](https://github.com/elixir-lang/plug) for use within the
  context of a Plug or [Phoenix](http://www.phoenixframework.org/)-based
  application.

  Bunyan also provides an error logger for use within a Plug/Phoenix-based
  application and a standard logger for manual use within any Elixir code.

  They all wrap the standard
  [Elixir Logger](http://elixir-lang.org/docs/stable/logger/Logger.html)
  and generate JSON log messages. This can be especially useful when used
  in conjunction with a service like [Splunk](https://www.splunk.com/).

  _photo credit: [Owlsmcgee](https://commons.wikimedia.org/wiki/File:Paul_Bunyan_statue_in_Bangor,_Maine.JPG)_

## Installation

  1. In `mix.exs`, add Bunyan to your list of dependencies:

    ```elixir
    def deps do
      [{:bunyan, "~> 0.1.0"}]
    end
    ```

    …and make sure Bunyan starts before your application:

    ```elixir
    def application do
      [applications: [:bunyan]]
    end
    ```

  2. In your config, set the Elixir logger to only output the message, and
    specify which HTTP headers and parameters to filter out, e.g.:

    ```elixir
    config :logger, :console,
      format: "$message\n",

    config :bunyan,
      filter_parameters: ["password", "ssn"]
    ```

  3. In a plug pipeline of your choosing, include `plug Plug.Bunyan`.

    For example, in a Phoenix application, you could add the plug to your
    `router.ex` by requiring Plug.Bunyan (i.e. `require Plug.Bunyan`) at the top
    of the file, and then adding `plug Plug.Bunyan` to one or more pipelines.

    Alternatively, if you would like Plug.Bunyan to log _all_ requests that pass
    through your Phoenix Controllers, you could add the plug directly to every
    Controller by modifying `your_app/web/web.ex`, like this:

    ```elixir
    defmodule YourApp.Web do
      ...

      def controller do
        quote do
          ...

          require Plug.Bunyan
          plug Plug.Bunyan
        end
      end

      ...
    end
    ```

  That's it. Now all requests that are processed by your plug pipeline will
  log the following fields:

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

### Logging Environment Variables

  If you wish to log any environment variables with `Plug.Bunyan`, provide
  Bunyan config with a list of environment variables to log along with your
  desired output names.

  For example:
  ```
  config :bunyan,
    env_vars: [{"CUSTOM_ENV_VAR", "our_env_var"}]
  ```

  ...will output the value of `CUSTOM_ENV_VAR` under a JSON key of `"our_env_var"`

### Error Logging

  In your plug pipeline (e.g. router.ex in a phoenix project):

  ```elixir
  require Logger
  use Plug.ErrorHandler

  defp handle_errors(conn, %{kind: _, reason: _, stack: _} = metadata) do
    Bunyan.ErrorLogger.log(conn, metadata)
    send_resp(conn, conn.status, Poison.encode!(%{errors: %{detail: "Internal server error"}}))
  end
  ```

  The following data will be captured:

  * `level`
  * `timestamp`
  * `request_id` (when used in conjuction with `Plug.RequestId`)
  * `method`
  * `host`
  * `path`
  * `status`
  * `logger_name`
  * `exception`

## Manual Usage

  To manually log, call the `Bunyan` module with your log level of choice, e.g.:

  ```elixir
  Bunyan.warn("something seems amiss")
  Bunyan.info(fn -> "a potentially expensive function" end)
  ```

  The log will contain the following fields:

  * `level`
  * `timestamp`
  * `logger_name`
  * `message`
  * `request_id` (when used in conjuction with `Plug.RequestId`)

## Contributing

  Before submitting your pull request, please run:

  * `mix test`
  * `mix credo --strict`
  * `mix dialyzer`
  * `mix coveralls`

