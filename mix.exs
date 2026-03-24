defmodule KinoDux.MixProject do
  use Mix.Project

  @version "0.1.0"
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
      aliases: aliases(),
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def cli do
    [preferred_envs: [check: :test]]
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
      {:kino_vega_lite, "~> 0.1", optional: true},
      {:dux, "~> 0.2.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
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
      source_ref: "v#{@version}",
      extras: ["README.md"],
      groups_for_modules: [
        "Rich Rendering": [KinoDux.LazyView, KinoDux.Progress],
        "Smart Cells": [
          KinoDux.SQLPreviewCell,
          KinoDux.SourceBrowserCell,
          KinoDux.ChartCell,
          KinoDux.FlameClusterCell
        ]
      ]
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test",
        "credo --strict"
      ]
    ]
  end
end
