defmodule Benchmarking.Tmp do
  alias Benchmarking.Random

  def make_tmp_dir do
    tmp_dir = Path.join([System.tmp_dir!(), "benchmarking-#{Random.random_string()}"])

    File.mkdir_p!(tmp_dir)
    tmp_dir
  end

  def make_tmp_dir(callback) do
    tmp_dir = make_tmp_dir()

    try do
      callback.(tmp_dir)
    after
      File.rm_rf(tmp_dir)
    end
  end
end
