# KinoDux

Livebook integrations for [Dux](https://github.com/elixir-dux/dux) — rich rendering and smart cells for DuckDB-native dataframes.

## Setup

```elixir
Mix.install([
  {:dux, "~> 1.0"},
  {:kino_dux, "~> 0.1"}
])
```

## Features

### Rich rendering

- **Lazy pipelines** — see source, operations, and generated SQL before computing
- **Computed results** — interactive data tables with column types and pagination
- **Graphs** — vertex/edge counts and metadata for `%Dux.Graph{}` structs

### Smart Cells

- **SQL Preview** — pick a Dux binding, see the generated SQL

## License

Apache-2.0
