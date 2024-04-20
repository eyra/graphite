defmodule Benchmarking do
  @moduledoc """
  Documentation for `Benchmarking`.
  """
  alias Benchmarking.Docker
  alias Benchmarking.Git
  alias Benchmarking.Tmp

  require Logger

  @scoring_image_name "benchmarking-scoring"
  @scoring_image_tag "latest"

  def main(args) do
    settings = args |> List.first() |> File.read!() |> Jason.decode!(keys: :atoms)
    output = File.stream!(Access.fetch!(settings, :results_file))

    settings
    |> Map.put(:headers, Access.fetch!(settings, :results_headers))
    |> run()
    |> Stream.into(output)
    |> Stream.run()
  end

  def run(params) do
    case build_scoring_image(params) do
      :ok ->
        process(params)

      {:error, message} ->
        Logger.error(message)
        []
    end
  end

  def build_scoring_image(%{template_repo: repo, template_repo_ref: ref}) do
    Tmp.make_tmp_dir(fn clone_dir ->
      with :ok <- Git.clone_repo(repo, clone_dir),
           :ok <- Git.reset_repo(clone_dir, ref),
           :ok <- Docker.build(clone_dir, @scoring_image_name, @scoring_image_tag) do
        :ok
      else
        {:error, message} -> {:error, "Build of scoring image failed: #{message}"}
      end
    end)
  end

  def process(%{repositories_file: repositories_file, results_headers: results_headers} = settings) do
    repositories_file
    |> Path.expand()
    |> File.stream!([read_ahead: 100_000], 1000)
    |> CSV.decode!(headers: true)
    |> Stream.flat_map(fn %{"url" => url, "ref" => ref, "submission-id" => id} ->
      url
      |> run_benchmark(ref, settings)
      |> Stream.map(&Map.merge(&1, %{"url" => url, "ref" => ref, "submission-id" => id}))
      |> Stream.map(&Map.put_new(&1, "status", get_status(&1)))
    end)
    |> CSV.encode(headers: ["submission-id", "url", "ref", "status", "error_message"] ++ results_headers)
  end

  def run_benchmark(repo, ref, %{
        score_volume_mounts: score_volume_mounts,
        score_entrypoint: score_entrypoint,
        score_args: score_args,
        score_file: score_file,
        prediction_volume_mounts: prediction_volume_mounts,
        prediction_args: prediction_args
      }) do
    repo_name = repo |> String.split("/") |> List.last() |> String.split(".") |> List.first()
    tag = ref

    with :ok <- build_prediction_image(repo, ref, repo_name, tag),
         :ok <- run_prediction_image(repo_name, tag, prediction_volume_mounts, prediction_args),
         {:ok, result} <- run_scoring(score_args, score_entrypoint, score_volume_mounts, score_file) do
      result
    else
      {:error, message} -> [%{"error_message" => message}]
    end
  end

  defp get_status(%{"error_message" => _}), do: "error"
  defp get_status(_), do: "success"

  defp build_prediction_image(repo, ref, repo_name, tag) do
    Tmp.make_tmp_dir(fn clone_dir ->
      with :ok <- Git.clone_repo(repo, clone_dir),
           :ok <- Git.reset_repo(clone_dir, ref) do
        Docker.build(clone_dir, repo_name, tag)
      end
    end)
  end

  defp run_prediction_image(repo_name, tag, prediction_volume_mounts, prediction_args) do
    volumes = map_volume_mounts(prediction_volume_mounts)

    Docker.run(repo_name, tag, prediction_args, volumes: volumes)
  end

  defp map_volume_mounts(volume_mounts) do
    for %{source: source, target: target} <- volume_mounts do
      {source, target}
    end
  end

  defp run_scoring(args, entrypoint, volumes, score_file) do
    with :ok <-
           Docker.run(
             @scoring_image_name,
             @scoring_image_tag,
             args,
             entrypoint: entrypoint,
             volumes: map_volume_mounts(volumes)
           ),
         :ok <- check_path(score_file) do
      try do
        result =
          score_file
          |> File.stream!()
          |> CSV.decode!(headers: true)
          |> Enum.into([])

        {:ok, result}
      rescue
        _ -> {:error, "Error reading scores.csv"}
      end
    else
      {:error, _message} -> [%{"error_message" => "Failed to run scoring container"}]
    end
  end

  defp check_path(path) do
    if File.exists?(path) do
      :ok
    else
      {:error, "No #{Path.basename(path)} found"}
    end
  end
end
