# Bunyan

**TODO: Add description**

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
