defmodule Benchmarking.Repo do
  def settings(repo_clone_dir) do
    settings_file = Path.join(repo_clone_dir, "settings.json")

    if File.exists?(settings_file) do
      case Jason.decode(File.read!(settings_file), keys: :atoms!) do
        {:ok, json} -> {:ok, json}
        {:error, _} -> {:error, "Error when reading settings.json"}
      end
    else
      {:ok, %{}}
    end
  end

  def dockerfile(repo_clone_dir) do
    case settings(repo_clone_dir) do
      {:ok, settings} -> {:ok, Access.get(settings, :dockerfile, "Dockerfile")}
      error -> error
    end
  end
end
