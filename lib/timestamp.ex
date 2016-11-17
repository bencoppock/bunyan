defmodule Bunyan.Timestamp do
  @moduledoc """
  Formats timestamps.
  """

  @timestamp_format "~4w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w.~6..0w"

  @doc """
  Formats timestamp as a String.

  ## Examples:
      iex> Bunyan.Timestamp.format_string({1479, 364210, 958720})
      "2016-11-17 06:30:10.958720"
  """
  @spec format_string({non_neg_integer, non_neg_integer, non_neg_integer}) :: String.t
  def format_string(timestamp) do
    timestamp
    |> format
    |> List.to_string
  end

  @doc """
  Formats timestamp as an IO List.

  ## Examples:
      iex> Bunyan.Timestamp.format({1479, 364210, 958720})
      ['2016', 45, '11', 45, '17', 32, ['0', 54], 58, '30', 58, '10', 46, '958720']
  """
  @spec format({non_neg_integer, non_neg_integer, non_neg_integer}) :: list
  def format({_,_,micro} = timestamp) do
    {{yr,month,day},{hr,min,sec}} = :calendar.now_to_universal_time(timestamp)
    :io_lib.format(@timestamp_format, [yr,month,day,hr,min,sec,micro])
  end
end
