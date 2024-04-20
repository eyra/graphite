defmodule Benchmarking.RandomTest do
  use ExUnit.Case, async: true

  alias Benchmarking.Random

  test "random_string/1 should return a string with the specified bit length" do
    result = Benchmarking.Random.random_string()

    # Assert that the result is a string
    assert is_binary(result)
  end

  test "random_string/1 should return unique strings for different inputs" do
    results = for _i <- 1..3, do: Benchmarking.Random.random_string()

    assert Enum.uniq(results) == results
  end
end
