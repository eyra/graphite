defmodule Benchmarking.TmpTest do
  use ExUnit.Case, async: true

  alias Benchmarking.Tmp

  test "make_tmp_dir creates a temporary directory and deletes it after the callback is executed" do
    callback = fn tmp_dir ->
      assert File.exists?(tmp_dir)
      Process.put(:tmp_dir, tmp_dir)
    end

    Tmp.make_tmp_dir(callback)

    refute File.exists?(Process.get(:tmp_dir))
  end

  test "make_tmp_dir raises an error if the callback raises an error" do
    callback = fn tmp_dir ->
      Process.put(:tmp_dir, tmp_dir)
      raise "Oops!"
    end

    assert_raise RuntimeError, fn ->
      Tmp.make_tmp_dir(callback)
    end

    refute File.exists?(Process.get(:tmp_dir))
  end

  test "make_tmp_dir creates a directory" do
    tmp_dir = Tmp.make_tmp_dir()

    assert File.dir?(tmp_dir)
    File.rm_rf(tmp_dir)
  end
end
