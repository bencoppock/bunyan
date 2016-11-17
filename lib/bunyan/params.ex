defmodule Bunyan.Params do
  @moduledoc """
  Provides filtering of parameters specified in the application config.

  ## More
  See `filter/1`
  """

  @type parameter :: {String.t, map | list | String.t}

  @filter_parameters Enum.map(
    Application.get_env(:bunyan, :filter_parameters, []),
    &String.downcase/1
  )

  @doc """
  Filters parameters recursively within maps and lists.

  ## Configuration
  Specify the keys to filter within config.exs, e.g.:

  ```
  config :params,
    filter_parameters: ["password", "ssn"]
  ```

  ## Examples:

      iex> Bunyan.Params.filter(%{"name" => "Paul", "ssn" => "123-45-6789"})
      %{"name" => "Paul", "ssn" => "[FILTERED]"}

      iex> Bunyan.Params.filter([%{"name" => "Paul"}, %{"ssn" => "123-45-6789"}])
      [%{"name" => "Paul"}, %{"ssn" => "[FILTERED]"}]
  """
  @spec filter(map) :: map
  def filter(params) when is_map(params) do
    params
    |> Enum.map(&filter/1)
    |> Enum.into(%{})
  end

  @spec filter(list) :: list
  def filter(params) when is_list(params) do
    params
    |> Enum.map(&filter/1)
  end

  @spec filter(String.t) :: String.t
  def filter(value) when is_binary(value), do: value

  @spec filter(parameter) :: parameter
  def filter({key, value}) do
    case String.downcase(key) in @filter_parameters do
      true -> {key, "[FILTERED]"}
         _ -> {key, filter(value)}
    end
  end
end
