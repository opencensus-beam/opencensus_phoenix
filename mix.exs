defmodule OpencensusPhoenix.MixProject do
  use Mix.Project

  @description "Integration between OpenCensus and Phoenix"

  def project do
    [
      app: :opencensus_phoenix,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/opencensus-beam/opencensus_phoenix",
        "OpenCensus" => "https://opencensus.io",
        "OpenCensus Erlang" => "https://github.com/census-instrumentation/opencensus-erlang",
        "OpenCensus BEAM" => "https://github.com/opencensus-beam"
      }
    ]
  end

  defp deps do
    [
      {:opencensus, "~> 0.9.0"},

      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
