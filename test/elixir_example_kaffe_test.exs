defmodule  ElixirKaffeCodealongTest do
  use ExUnit.Case
  doctest ElixirKaffeCodealong

  test "greets the world" do
    assert ElixirKaffeCodealong.hello() == :world
  end
end
