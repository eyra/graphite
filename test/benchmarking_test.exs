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
      cmd(template_repo_dir, "git", ["init"])
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
    tmp_dir
    |> write("input.csv", "-")
    |> write("outcomes.csv", "-")
    |> write(
      "repositories.csv",
      """
      id,url,ref
      1,file://#{clone_dir},#{ref}
      """
    )

    {:ok, template_repo_dir: template_repo_dir, ref: ref}
  end

  test "run successful", %{tmp_dir: tmp_dir, template_repo_dir: template_repo_dir, ref: ref} do
    # Run benchmarking
    [header, row] =
      %{
        template_repo: "file://#{template_repo_dir}",
        template_repo_ref: ref,
        repositories: Path.join(tmp_dir, "repositories.csv"),
        benchmark_data: Path.join(tmp_dir, "input.csv"),
        outcomes_data: Path.join(tmp_dir, "outcomes.csv"),
        headers: ["score"]
      }
      |> Benchmarking.run()
      |> Enum.into([])

    # Check results
    assert header == "id,status,error_message,score\r\n"
    assert row == "1,success,,2\r\n"
  end

  test "run with error", %{tmp_dir: tmp_dir, template_repo_dir: template_repo_dir, ref: ref} do
    # Add a non-existing repo
    write(tmp_dir, "repositories.csv", """
    id,url,ref
    1,file://#{tmp_dir}/non-existing,#{ref}
    """)

    # Run benchmarking
    [_header, row] =
      %{
        template_repo: "file://#{template_repo_dir}",
        template_repo_ref: ref,
        repositories: Path.join(tmp_dir, "repositories.csv"),
        benchmark_data: Path.join(tmp_dir, "input.csv"),
        outcomes_data: Path.join(tmp_dir, "outcomes.csv"),
        headers: ["score"]
      }
      |> Benchmarking.run()
      |> Enum.into([])

    # Check results
    assert row == "1,error,Failed to clone repo,\r\n"
  end
end
