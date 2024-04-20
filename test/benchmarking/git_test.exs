defmodule Benchmarking.GitTest do
  use Benchmarking.FSCase, async: true

  alias Benchmarking.Git

  test "clone_repo clones the repository", %{tmp_dir: tmp_dir} do
    tmp_dir
    |> cmd("git", ["init"])
    |> cmd("touch", ["README.md"])
    |> cmd("git", ["add", "."])
    |> cmd("git", ["commit", "-m", "Initial commit"])

    Tmp.make_tmp_dir(fn clone_dir ->
      Git.clone_repo("file://#{tmp_dir}", clone_dir)
      assert File.exists?(Path.join(clone_dir, "README.md"))
    end)
  end

  test "clone_repo clones the correct branch", %{tmp_dir: tmp_dir} do
    tmp_dir
    |> cmd("git", ["init"])
    |> cmd("touch", ["README.md"])
    |> cmd("git", ["add", "."])
    |> cmd("git", ["commit", "-m", "Initial commit"])
    |> cmd("git", ["branch", "test"])
    |> cmd("git", ["checkout", "-q", "test"])
    |> cmd("touch", ["test.txt"])
    |> cmd("git", ["add", "."])
    |> cmd("git", ["commit", "-m", "Add test.txt"])

    Tmp.make_tmp_dir(fn clone_dir ->
      Git.clone_repo("file://#{tmp_dir}", clone_dir)
      Git.reset_repo(clone_dir, "test")
      assert File.exists?(Path.join(clone_dir, "test.txt"))
    end)
  end

  test "clone_repo clones the correct ref", %{tmp_dir: tmp_dir} do
    tmp_dir
    |> cmd("git", ["init"])
    |> cmd("touch", ["README.md"])
    |> cmd("git", ["add", "."])
    |> cmd("git", ["commit", "-m", "Initial commit"])

    {_, %{output: ref}} = cmd(tmp_dir, "git", ["show-ref", "--hash"])

    tmp_dir
    |> cmd("git", ["rm", "README.md"])
    |> cmd("git", ["commit", "-m", "Removed README.md"])

    Tmp.make_tmp_dir(fn clone_dir ->
      Git.clone_repo("file://#{tmp_dir}", clone_dir)
      Git.reset_repo(clone_dir, String.trim(ref))

      assert File.exists?(Path.join(clone_dir, "README.md"))
    end)
  end
end
