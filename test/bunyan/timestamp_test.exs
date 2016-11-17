defmodule Bunyan.TimestampTest do
  use ExUnit.Case
  doctest Bunyan.Timestamp

  @pattern ~r/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{6}\z/

  test "returns a correctly-formatted timestamp as a string" do
    formatted_timestamp = Bunyan.Timestamp.format_string(:os.timestamp)
    assert Regex.match?(@pattern, formatted_timestamp)
  end
end
