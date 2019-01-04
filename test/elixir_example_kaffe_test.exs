defmodule  ElixirExampleKaffeTest do
  use ExUnit.Case
  doctest ElixirExampleKaffe

  test "greets the world" do
    assert ElixirExampleKaffe.hello() == :world
  end
end
