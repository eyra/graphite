defmodule Benchmarking.Git do
  @moduledoc false
  require IEx

  def clone_repo(repo, target_folder) do
    {_, status} = System.cmd("git", ["clone", "-q", repo, "."], cd: target_folder, stderr_to_stdout: true)

    case status do
      0 -> :ok
      _ -> {:error, "Failed to clone repo: #{repo}"}
    end
  end

  def reset_repo(repo, ref) do
    {_, status} = System.cmd("git", ["reset", "-q", "--hard", ref], cd: repo, stderr_to_stdout: true)

    case status do
      0 -> :ok
      _ -> {:error, "Failed to reset repo to ref"}
    end
  end
end
