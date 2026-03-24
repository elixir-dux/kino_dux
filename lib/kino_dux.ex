defmodule KinoDux do
  @moduledoc """
  Livebook integrations for Dux.

  `kino_dux` provides rich rendering for `%Dux{}` dataframes and `%Dux.Graph{}`
  structs in Livebook, plus smart cells for common data workflows.

  ## Setup

  Add to your Livebook setup cell:

      Mix.install([
        {:dux, "~> 0.2.0"},
        {:kino_dux, "~> 0.1"}
      ])

  ## Rich Rendering

  Once installed, `%Dux{}` and `%Dux.Graph{}` structs render automatically:

  - **Lazy pipelines** — source provenance (CSV, Parquet, attached database, SQL),
    accumulated operations, distribution info, and generated SQL
  - **Computed results** — interactive data tables with column types, sorting,
    and pagination via `Kino.DataTable`
  - **Graphs** — vertex ID, edge columns, and worker distribution for `%Dux.Graph{}`

  ## Smart Cells

  Four smart cells register at startup:

  - **Dux SQL Preview** — pick a `%Dux{}` binding, see the generated SQL
  - **Dux Data Source** — form-driven source selection (Parquet, CSV, NDJSON, SQL,
    attached databases) that generates `Dux.from_*` code
  - **Dux Chart** — VegaLite chart builder with chart type, axis, and color selection
  - **Dux FLAME Cluster** — configure `Dux.Flame` elastic compute pools

  ## Distributed Query Progress

  `KinoDux.Progress` provides a live progress widget for distributed queries:

      progress = KinoDux.Progress.new()
      Kino.render(progress.frame)

  The widget subscribes to Dux telemetry events and shows real-time fan-out,
  worker execution, and merge status.
  """
end
