defmodule Benchmarking.FSCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Benchmarking.Tmp

  using _options do
    quote do
      import Benchmarking.FSCase

      alias Benchmarking.Tmp
    end
  end

  setup _tags do
    tmp_dir = Tmp.make_tmp_dir()
    on_exit(fn -> File.rm_rf(tmp_dir) end)

    {:ok, tmp_dir: tmp_dir}
  end

  def cmd({cwd, _}, cmd, args) do
    {output, status} = System.cmd(cmd, args, cd: cwd)
    {cwd, %{output: String.trim(output), status: status}}
  end

  def cmd(cwd, cmd, args) when is_binary(cwd) do
    cmd({cwd, nil}, cmd, args)
  end

  def write({cwd, _}, path, contents) do
    write(cwd, path, contents)
  end

  def write(cwd, path, contents) do
    cwd
    |> Path.join(path)
    |> File.write!(contents)

    {cwd, nil}
  end

  def copy({cwd, _}, path) do
    copy(cwd, path)
  end

  def copy(cwd, path) do
    File.cp_r!(path, Path.join(cwd, Path.basename(path)))

    {cwd, nil}
  end
end
