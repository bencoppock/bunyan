defmodule Bunyan.ParamsTest do
  use ExUnit.Case
  doctest Bunyan.Params

  test "filters params per the \"filter_parameters\" configuration" do
    params = %{"name" => "Babe", "password" => "pass123"}
    assert Bunyan.Params.filter(params) == %{"name" => "Babe", "password" => "[FILTERED]"}
  end

  test "treats the filter_paramters configuration as case insensitive" do
    params = %{"Name" => "Babe", "Password" => "pass123"}
    assert Bunyan.Params.filter(params) == %{"Name" => "Babe", "Password" => "[FILTERED]"}
  end

  test "filters maps and lists recursively" do
    params = %{
      "password" => "pass123",
      "user" => %{
        "name" => "Babe the Blue Ox",
        "things" => [
          %{"SSN" => %{"first_three" => "123", "next_two" => "12", "and_the_rest" => "1234"}},
          %{"fav_color" => "likely Blue"},
          "ooh, gnarly list!",
          %{"sauce" => "ketchup"},
          %{"secret|sauce" => "mustard"}
        ]
      }
    }

    assert Bunyan.Params.filter(params) == %{
      "password" => "[FILTERED]",
      "user" => %{
        "name" => "Babe the Blue Ox",
        "things"  => [
          %{"SSN"    => "[FILTERED]"},
          %{"fav_color" => "likely Blue"},
          "ooh, gnarly list!",
          %{"sauce" => "ketchup"},
          %{"secret|sauce" => "[FILTERED]"}
        ]
      }
    }
  end
end
