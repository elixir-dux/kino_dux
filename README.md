# KinoDux

[![Hex.pm](https://img.shields.io/hexpm/v/kino_dux.svg)](https://hex.pm/packages/kino_dux)
[![Docs](https://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/kino_dux)

Livebook integrations for [Dux](https://github.com/elixir-dux/dux) — rich rendering and smart cells for DuckDB-native dataframes.

## Setup

```elixir
Mix.install([
  {:dux, "~> 0.2.0"},
  {:kino_dux, "~> 0.1"}
])
```

## Features

### Rich rendering

- **Lazy pipelines** — see source provenance (CSV, Parquet, attached database, SQL), accumulated operations, and generated SQL before computing
- **Computed results** — interactive data tables with column types, sorting, and pagination
- **Graphs** — vertex/edge metadata and distribution info for `%Dux.Graph{}` structs

### Smart Cells

- **SQL Preview** — pick a Dux binding, see the generated SQL
- **Source Browser** — form-driven source selection (Parquet, CSV, NDJSON, SQL, attached databases)
- **Chart** — VegaLite chart builder with axis and chart type selection
- **FLAME Cluster** — configure `Dux.Flame` elastic compute pools

## License

Apache-2.0
