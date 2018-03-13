defmodule GraphqlExampleTest do
  use ExUnit.Case
  doctest GraphqlExample

  test "greets the world" do
    assert GraphqlExample.hello() == :world
  end
end
