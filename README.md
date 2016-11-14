# Bunyan

A JSON logger for Elixir.

![Paul Bunyan the Logger, by Owlsmcgee https://commons.wikimedia.org/wiki/File:Paul_Bunyan_statue_in_Bangor,_Maine.JPG](/paul_bunyan.png?raw=true)

Bunyan provides a [Plug](https://github.com/elixir-lang/plug) that wraps the
[standard Elixir Logger](http://elixir-lang.org/docs/stable/logger/Logger.html)
and automatically generates JSON log messages.

View documentation for Bunyan and Bunyan.Plug modules from iex.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `bunyan` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:bunyan, "~> 0.1.0"}]
    end
    ```

  2. Ensure `bunyan` is started before your application:

    ```elixir
    def application do
      [applications: [:bunyan]]
    end
    ```

## Contributing
Before submitting your pull request, please run:
  * `mix test`
  * `mix credo --strict`
  * `mix dialyzer`
  * `mix coveralls`
