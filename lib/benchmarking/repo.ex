defmodule Benchmarking.Repo do
  def settings(repo_clone_dir) do
    case File.read(Path.join(repo_clone_dir, "settings.json")) do
      {:ok, json} -> Jason.decode!(json, keys: :atoms!)
      {:error, _error} -> %{dockerfile: "Dockerfile"}
    end
  end

  def dockerfile(repo_clone_dir) do
    repo_clone_dir
    |> settings()
    |> Access.fetch!(:dockerfile)
  end
end
