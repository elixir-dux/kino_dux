defmodule KinoDux.MixProject do
  use Mix.Project

  @version "0.1.0-dev"
  @source_url "https://github.com/elixir-dux/kino_dux"

  def project do
    [
      app: :kino_dux,
      name: "KinoDux",
      description: "Livebook integrations for Dux — rich rendering and smart cells",
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [
      mod: {KinoDux.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:kino, "~> 0.14"},
      {:dux, github: "elixir-dux/dux"},
      {:ex_doc, "~> 0.36", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
      },
      maintainers: ["Christopher Grainger"]
    ]
  end

  defp docs do
    [
      main: "KinoDux",
      source_ref: "v#{@version}"
    ]
  end
end
