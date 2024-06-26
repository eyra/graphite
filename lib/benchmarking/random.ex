defmodule Benchmarking.Random do
  @moduledoc false
  def random_string(bit_length \\ 16) do
    bit_length
    |> :crypto.strong_rand_bytes()
    |> Base.encode16()
  end
end
