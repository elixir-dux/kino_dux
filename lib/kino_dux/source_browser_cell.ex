defmodule KinoDux.SourceBrowserCell do
  @moduledoc false

  # Smart Cell for browsing data sources and generating Dux.from_*() code.
  # Supports local files (CSV, Parquet, NDJSON), S3 paths, and raw SQL.

  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Dux Data Source"

  @impl true
  def init(attrs, ctx) do
    fields = %{
      source_type: attrs["source_type"] || "parquet",
      path: attrs["path"] || "",
      variable: attrs["variable"] || "df",
      csv_delimiter: attrs["csv_delimiter"] || ",",
      csv_header: attrs["csv_header"] || true
    }

    {:ok, assign(ctx, fields: fields)}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, ctx.assigns.fields, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    fields = Map.put(ctx.assigns.fields, field, value)
    broadcast_event(ctx, "update", fields)
    {:noreply, assign(ctx, fields: fields)}
  end

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(attrs) do
    variable = attrs["variable"]
    path = attrs["path"]

    if variable == "" or path == "" do
      ""
    else
      case attrs["source_type"] do
        "parquet" ->
          ~s(#{variable} = Dux.from_parquet("#{escape_string(path)}"))

        "csv" ->
          opts = csv_opts(attrs)
          if opts == "" do
            ~s(#{variable} = Dux.from_csv("#{escape_string(path)}"))
          else
            ~s(#{variable} = Dux.from_csv("#{escape_string(path)}", #{opts}))
          end

        "ndjson" ->
          ~s(#{variable} = Dux.from_ndjson("#{escape_string(path)}"))

        "sql" ->
          ~s(#{variable} = Dux.from_query("#{escape_string(path)}"))

        _ ->
          ""
      end
    end
  end

  defp csv_opts(attrs) do
    opts = []

    opts =
      if attrs["csv_delimiter"] && attrs["csv_delimiter"] != "," do
        opts ++ [~s(delimiter: "#{escape_string(attrs["csv_delimiter"])}")]
      else
        opts
      end

    opts =
      if attrs["csv_header"] == false do
        opts ++ ["header: false"]
      else
        opts
      end

    Enum.join(opts, ", ")
  end

  defp escape_string(s) do
    String.replace(s, "\"", "\\\"")
  end

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500&display=swap");

      const style = `
        .dux-source { font-family: 'Fira Code', monospace; font-size: 13px; padding: 12px; }
        .dux-source label { color: #9b9588; display: inline-block; width: 80px; }
        .dux-source input, .dux-source select {
          background: #1a1918; border: 1px solid #2a2724; border-radius: 4px;
          padding: 4px 8px; color: #e8e4de; font-family: 'Fira Code', monospace;
          font-size: 13px; margin-left: 8px;
        }
        .dux-source select { width: 120px; }
        .dux-source input[type="text"] { width: 400px; }
        .dux-source .row { margin-bottom: 8px; display: flex; align-items: center; }
        .dux-source .hint { font-size: 11px; color: #6b665e; margin-left: 92px; }
      `;

      const styleEl = document.createElement("style");
      styleEl.textContent = style;

      const container = document.createElement("div");
      container.className = "dux-source";

      container.innerHTML = `
        <div class="row">
          <label>Type</label>
          <select id="source_type">
            <option value="parquet">Parquet</option>
            <option value="csv">CSV</option>
            <option value="ndjson">NDJSON</option>
            <option value="sql">Raw SQL</option>
          </select>
        </div>
        <div class="row">
          <label id="path-label">Path</label>
          <input type="text" id="path" placeholder="path/to/data.parquet or s3://bucket/data/**/*.parquet" />
        </div>
        <div class="hint" id="hint">Supports local paths, S3 URIs, and glob patterns</div>
        <div class="row">
          <label>Variable</label>
          <input type="text" id="variable" style="width:120px;" placeholder="df" />
        </div>
      `;

      ctx.root.appendChild(styleEl);
      ctx.root.appendChild(container);

      const typeEl = container.querySelector("#source_type");
      const pathEl = container.querySelector("#path");
      const varEl = container.querySelector("#variable");
      const labelEl = container.querySelector("#path-label");
      const hintEl = container.querySelector("#hint");

      // Set initial values
      typeEl.value = payload.source_type || "parquet";
      pathEl.value = payload.path || "";
      varEl.value = payload.variable || "df";
      updateHint(typeEl.value);

      function updateHint(type) {
        const hints = {
          parquet: "Supports local paths, S3 URIs, and glob patterns",
          csv: "Local or S3 path to CSV file",
          ndjson: "Local or S3 path to newline-delimited JSON",
          sql: "Any DuckDB SQL query (e.g. SELECT * FROM read_parquet(...))"
        };
        const labels = { parquet: "Path", csv: "Path", ndjson: "Path", sql: "SQL" };
        hintEl.textContent = hints[type] || "";
        labelEl.textContent = labels[type] || "Path";
      }

      typeEl.addEventListener("change", (e) => {
        updateHint(e.target.value);
        ctx.pushEvent("update_field", { field: "source_type", value: e.target.value });
      });
      pathEl.addEventListener("change", (e) => {
        ctx.pushEvent("update_field", { field: "path", value: e.target.value });
      });
      varEl.addEventListener("change", (e) => {
        ctx.pushEvent("update_field", { field: "variable", value: e.target.value });
      });

      ctx.handleEvent("update", (data) => {
        typeEl.value = data.source_type;
        pathEl.value = data.path;
        varEl.value = data.variable;
        updateHint(data.source_type);
      });
    }
    """
  end
end
