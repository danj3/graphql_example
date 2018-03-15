defmodule GExampleTest do
  use ExUnit.Case
  doctest GExample

  test "greets the world" do
    assert GExample.hello() == :world
  end
end
