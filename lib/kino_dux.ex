defmodule KinoDux do
  @moduledoc """
  Livebook integrations for Dux.

  `kino_dux` provides rich rendering for `%Dux{}` dataframes and `%Dux.Graph{}`
  structs in Livebook, plus smart cells for SQL preview, source browsing, and
  chart building.

  ## Setup

  Add to your Livebook setup cell:

      Mix.install([
        {:dux, "~> 1.0"},
        {:kino_dux, "~> 0.1"}
      ])

  ## What you get

  - **Lazy pipeline rendering** — see operations, generated SQL, and action buttons
  - **Computed result tables** — paginated data tables with column types
  - **Graph rendering** — vertex/edge counts and algorithm metadata
  - **SQL Preview Smart Cell** — pick a binding, see the generated SQL
  """
end
