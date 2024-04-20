defmodule Benchmarking.DockerTest do
  use ExUnit.Case, async: true

  alias Benchmarking.Random

  # setup do
  #   on_exit(fn ->
  #     {output, 0} = System.cmd("docker", ["images", "--format=json"])
  #     images = Jason.decode!(output)
  #   end)

  #   :ok
  # end

  setup do
    tag = String.downcase(Random.random_string())
    {:ok, tag: tag}
  end

  # test "build should build a Docker image", %{tag: tag} do
  #   Benchmarking.Docker.build(__DIR__, tag)

  #   # Assert that the image was built
  #   {output, 0} = System.cmd("docker", ["images", "-q", tag])
  #   assert output != ""
  # end

  # test "run should run a Docker container", %{tag: tag} do
  #   args = ["echo", "Hello, world!"]
  #   Benchmarking.Docker.run(tag, args)

  #   # Assert that the container ran and printed "Hello, world!"
  #   assert System.cmd("docker", ["logs", tag]) == "Hello, world!\n"
  # end

  test "images should return a list of images", %{tag: tag} do
    Benchmarking.Docker.build(__DIR__, "docker-test", tag)

    images = Benchmarking.Docker.images()
    assert Enum.any?(images, &(&1.repository == "docker-test" && &1.tag == tag))
  end
end
