defmodule BenchmarkingTest do
  use Benchmarking.FSCase

  alias Benchmarking.Git

  setup %{tmp_dir: tmp_dir} do
    # Create directories
    for dir <- ["template_repo", "clone"] do
      path = Path.join(tmp_dir, dir)
      File.mkdir_p!(path)
    end

    # Create template repo
    template_repo_dir = Path.join(tmp_dir, "template_repo")

    {_, %{output: ref}} =
      template_repo_dir
      |> cmd("git", ["init"])
      |> write(
        "Dockerfile",
        """
        FROM python:3.11-alpine
        COPY script.py script.py
        ENTRYPOINT ["python3", "script.py"]
        """
      )
      |> copy(Path.join(__DIR__, "script.py"))
      |> cmd("git", ["add", "."])
      |> cmd("git", ["commit", "-m", "Initial commit"])
      |> cmd("git", ["show-ref", "--hash"])

    # Create clone with algorithm
    clone_dir = Path.join(tmp_dir, "clone")
    Git.clone_repo("file://#{template_repo_dir}", clone_dir)
    # Create benchmark data
    repo_url = "file://#{clone_dir}"

    tmp_dir
    |> write("input.csv", "-")
    |> write("outcomes.csv", "-")
    |> write(
      "repositories.csv",
      """
      submission-id,url,ref
      1,#{repo_url},#{ref}
      """
    )

    {:ok, template_repo_dir: template_repo_dir, ref: ref, repo_url: repo_url}
  end

  test "run successful", %{tmp_dir: tmp_dir, template_repo_dir: template_repo_dir, repo_url: repo_url, ref: ref} do
    # Run benchmarking
    [row] =
      %{
        template_repo: "file://#{template_repo_dir}",
        template_repo_ref: ref,
        repositories_file: Path.join(tmp_dir, "repositories.csv"),
        prediction_volume_mounts: [
          %{source: tmp_dir, target: "/data"}
        ],
        prediction_args: [
          "predict",
          "/data/input.csv",
          "--output",
          "/data/predictions.csv"
        ],
        score_volume_mounts: [
          %{source: tmp_dir, target: "/data"}
        ],
        score_args: [
          "score",
          "/data/predictions.csv",
          "/data/not-used.csv",
          "--output",
          "/data/outcomes.csv"
        ],
        score_file: Path.join(tmp_dir, "outcomes.csv"),
        results_file: "results.csv",
        results_headers: ["score"]
      }
      |> Benchmarking.run()
      |> CSV.decode!(headers: true)
      |> Enum.into([])

    # Check results
    # assert header == "submission-id,url,ref,status,error_message,score\r\n"
    # assert row == "1,success,,2\r\n"
    assert %{
             "error_message" => "",
             "ref" => ^ref,
             "score" => "2",
             "status" => "success",
             "submission-id" => "1",
             "url" => ^repo_url
           } = row
  end

  test "run with error", %{tmp_dir: tmp_dir, template_repo_dir: template_repo_dir, ref: ref} do
    repo_url = "file://#{tmp_dir}/non-existing"
    # Add a non-existing repo
    write(tmp_dir, "repositories.csv", """
    submission-id,url,ref
    1,#{repo_url},#{ref}
    """)

    # Run benchmarking
    [row] =
      %{
        template_repo: "file://#{template_repo_dir}",
        template_repo_ref: ref,
        repositories_file: Path.join(tmp_dir, "repositories.csv"),
        prediction_volume_mounts: [
          %{source: tmp_dir, target: "/data"}
        ],
        prediction_args: [
          "predict",
          "/data/input.csv",
          "--output",
          "/data/predictions.csv"
        ],
        score_volume_mounts: [
          %{source: tmp_dir, target: "/data"}
        ],
        score_args: [
          "score",
          "/data/predictions.csv",
          "/data/not-used.csv",
          "--output",
          "/data/outcomes.csv"
        ],
        score_file: Path.join(tmp_dir, "outcomes.csv"),
        results_file: "results.csv",
        results_headers: ["score"]
      }
      |> Benchmarking.run()
      |> CSV.decode!(headers: true)
      |> Enum.into([])

    # Check results
    message = "Failed to clone repo: #{repo_url}"

    assert %{
             "error_message" => ^message,
             "ref" => ref,
             "score" => "",
             "status" => "error",
             "submission-id" => "1",
             "url" => ^repo_url
           } = row
  end
end
