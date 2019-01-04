defmodule ElixirExampleKaffe.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_example_kaffe,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :kaffe],
      mod: {ElixirExampleKaffe.Application, []}
      # now that we're using the Application module, this is where we'll tell it to start.
      # We use the keyword `mod` with applications that start a supervision tree,
      # which we configured when adding our Kaffe.Consumer to Application above.
    ]
  end

  defp deps do
    [
      {:kaffe, "~> 1.9"},
      {:brod, "~> 3.4.0"},
      {:kafka_protocol, "~> 1.1.0"}
    ]
  end
end
