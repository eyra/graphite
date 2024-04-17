defmodule Benchmarking.Docker do
  alias Benchmarking.Docker.Image

  def build(path, repository, tag) do
    {_, status} =
      System.cmd("docker", ["build", "-q", "-t", "#{repository}:#{tag}", "."], cd: path)

    case status do
      0 -> :ok
      _ -> {:error, "Failed to build image"}
    end
  end

  @spec run(String.t(), String.t(), [String.t()], Keyword.t()) :: :ok | {:error, String.t()}
  def run(repository, tag, args, opts \\ []) do
    volumes =
      opts
      |> Keyword.get(:volumes, [])
      |> Enum.map(fn {host, container} -> "--volume=#{Path.absname(host)}:#{container}" end)

    {_, status} =
      System.cmd(
        "docker",
        ["run", "--rm", "--network", "none"] ++ volumes ++ ["#{repository}:#{tag}"] ++ args
      )

    case status do
      0 -> :ok
      _ -> {:error, "Failed to run container"}
    end
  end

  def cleanup(image_id) do
    {_, 0} = System.cmd("docker", ["rmi", image_id])
  end

  def images do
    {output, 0} = System.cmd("docker", ["images", "--format=json"])

    output
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&Jason.decode!/1)
    |> Enum.map(&%Image{repository: &1["Repository"], tag: &1["Tag"], id: &1["ID"]})
  end
end