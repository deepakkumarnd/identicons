defmodule IdenticonTest do
  use ExUnit.Case
  doctest Identicon

  test "accepts a string as argument" do
    assert_raise FunctionClauseError, fn -> Identicon.generate({}) end
  end
end
