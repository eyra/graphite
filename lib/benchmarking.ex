defmodule Benchmarking do
  @moduledoc """
  Documentation for `Benchmarking`.
  """
  alias Benchmarking.Git
  alias Benchmarking.Tmp
  alias Benchmarking.Docker

  @scoring_image_name "benchmarking-scoring"
  @scoring_image_tag "latest"

  def main(args) do
    {parsed, _, _} =
      OptionParser.parse(args,
        strict: [
          template_repo: :string,
          template_repo_ref: :string,
          repositories: :string,
          benchmark_data: :string,
          outcomes_data: :string,
          output: :string,
          headers: :string
        ]
      )

    output = File.stream!(Keyword.get(parsed, :output))

    parsed
    |> Map.new()
    |> Map.put(:headers, Keyword.get(parsed, :headers) |> String.split(","))
    |> run()
    |> Stream.into(output)
    |> Stream.run()
  end

  def run(params) do
    build_scoring_image(params)

    process(params)

    # Cleanup template repo
    # Cleanup scoring image
    # Write scores to file
  end

  def build_scoring_image(%{template_repo: repo, template_repo_ref: ref}) do
    Tmp.make_tmp_dir(fn clone_dir ->
      Git.clone_repo(repo, clone_dir)
      Git.reset_repo(clone_dir, ref)
      Docker.build(clone_dir, @scoring_image_name, @scoring_image_tag)
    end)
  end

  def process(%{
        repositories: repositories_csv,
        benchmark_data: benchmark_data,
        outcomes_data: outcomes_data,
        headers: headers
      }) do
    File.stream!(Path.expand(repositories_csv), [read_ahead: 100_000], 1000)
    |> CSV.decode!(headers: true)
    |> Stream.flat_map(fn %{"url" => url, "ref" => ref, "id" => id} ->
      url
      |> run_benchmark(ref, benchmark_data, outcomes_data)
      |> Stream.map(&Map.put(&1, "id", id))
      |> Stream.map(&Map.put_new(&1, "status", get_status(&1)))
    end)
    |> CSV.encode(headers: ["id", "status", "error_message"] ++ headers)
  end

  def run_benchmark(repo, ref, benchmark_data, outcomes_data) do
    repo_name = repo |> String.split("/") |> List.last() |> String.split(".") |> List.first()
    tag = ref

    Tmp.make_tmp_dir(fn predictions_dir ->
      with :ok <- build_prediction_image(repo, ref, repo_name, tag),
           :ok <- run_prediction_image(repo_name, tag, benchmark_data, predictions_dir),
           :ok <- check_path(Path.join(predictions_dir, "predictions.csv")) do
        outcomes_dir = Path.expand(Path.dirname(outcomes_data))

        Tmp.make_tmp_dir(fn scores_dir ->
          scores_path = Path.join(scores_dir, "scores.csv")

          with :ok <-
                 Docker.run(
                   @scoring_image_name,
                   @scoring_image_tag,
                   [
                     "score",
                     "/predictions/predictions.csv",
                     "/outcomes/#{Path.basename(outcomes_data)}",
                     "--out=/scores/scores.csv"
                   ],
                   volumes: [
                     {outcomes_dir, "/outcomes"},
                     {predictions_dir, "/predictions"},
                     {scores_dir, "/scores"}
                   ]
                 ),
               :ok <- check_path(scores_path) do
            try do
              File.stream!(scores_path)
              |> CSV.decode!(headers: true)
              |> Enum.into([])
            rescue
              _ -> {:error, "Error reading scores.csv"}
            end
          else
            {:error, _message} -> [%{"error_message" => "Failed to run scoring container"}]
          end
        end)
      else
        {:error, message} -> [%{"error_message" => message}]
      end
    end)
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

  defp run_prediction_image(repo_name, tag, benchmark_data, predictions_dir) do
    data_folder = Path.dirname(Path.expand(benchmark_data))

    Docker.run(
      repo_name,
      tag,
      [
        "predict",
        "/data/#{Path.basename(benchmark_data)}",
        "--out=/predictions/predictions.csv"
      ],
      volumes: [
        {data_folder, "/data"},
        {predictions_dir, "/predictions"}
      ]
    )
  end

  defp check_path(path) do
    if File.exists?(path) do
      :ok
    else
      {:error, "No #{Path.basename(path)} found"}
    end
  end
end
