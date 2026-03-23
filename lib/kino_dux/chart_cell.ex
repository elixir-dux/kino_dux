defmodule KinoDux.ChartCell do
  @moduledoc false

  # Smart Cell for building VegaLite charts from a Dux binding.
  # Generates reproducible VegaLite code with axis selection,
  # chart type, and color encoding.

  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Dux Chart"

  @impl true
  def init(attrs, ctx) do
    fields = %{
      binding: attrs["binding"] || "",
      chart_type: attrs["chart_type"] || "bar",
      x: attrs["x"] || "",
      y: attrs["y"] || "",
      color: attrs["color"] || "",
      title: attrs["title"] || ""
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
    binding = attrs["binding"]
    x = attrs["x"]
    y = attrs["y"]

    if binding == "" or x == "" or y == "" do
      ""
    else
      chart_type = attrs["chart_type"] || "bar"
      color = attrs["color"]
      title = attrs["title"]

      mark = vl_mark(chart_type)

      lines = [
        ~s(#{binding}),
        ~s(|> Dux.to_rows()),
        ~s(|> VegaLite.new(#{title_opt(title)})),
        ~s(|> VegaLite.#{mark}()),
        ~s(|> VegaLite.encode_field(:x, "#{x}"#{type_hint(chart_type, :x)})),
        ~s(|> VegaLite.encode_field(:y, "#{y}"#{type_hint(chart_type, :y)}))
      ]

      lines =
        if color != "" do
          lines ++ [~s(|> VegaLite.encode_field(:color, "#{color}"))]
        else
          lines
        end

      Enum.join(lines, "\n")
    end
  end

  defp vl_mark("bar"), do: "mark(:bar)"
  defp vl_mark("line"), do: "mark(:line)"
  defp vl_mark("point"), do: "mark(:point)"
  defp vl_mark("area"), do: "mark(:area)"
  defp vl_mark(_), do: "mark(:bar)"

  defp type_hint("bar", :x), do: ~s(, type: :nominal)
  defp type_hint("bar", :y), do: ~s(, type: :quantitative)
  defp type_hint("line", :x), do: ~s(, type: :temporal)
  defp type_hint("line", :y), do: ~s(, type: :quantitative)
  defp type_hint(_, _), do: ""

  defp title_opt(""), do: ""
  defp title_opt(title), do: ~s(title: "#{title}")

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500&display=swap");

      const style = `
        .dux-chart { font-family: 'Fira Code', monospace; font-size: 13px; padding: 12px; }
        .dux-chart label { color: #9b9588; display: inline-block; width: 80px; }
        .dux-chart input, .dux-chart select {
          background: #1a1918; border: 1px solid #2a2724; border-radius: 4px;
          padding: 4px 8px; color: #e8e4de; font-family: 'Fira Code', monospace;
          font-size: 13px; margin-left: 8px;
        }
        .dux-chart select { width: 120px; }
        .dux-chart input { width: 160px; }
        .dux-chart .row { margin-bottom: 8px; display: flex; align-items: center; }
        .dux-chart .hint { font-size: 11px; color: #6b665e; margin-top: 4px; margin-left: 92px; }
      `;

      const styleEl = document.createElement("style");
      styleEl.textContent = style;

      const container = document.createElement("div");
      container.className = "dux-chart";

      container.innerHTML = `
        <div class="row">
          <label>Data</label>
          <input type="text" id="binding" placeholder="pipeline" />
        </div>
        <div class="row">
          <label>Chart</label>
          <select id="chart_type">
            <option value="bar">Bar</option>
            <option value="line">Line</option>
            <option value="point">Scatter</option>
            <option value="area">Area</option>
          </select>
        </div>
        <div class="row">
          <label>X axis</label>
          <input type="text" id="x" placeholder="column name" />
        </div>
        <div class="row">
          <label>Y axis</label>
          <input type="text" id="y" placeholder="column name" />
        </div>
        <div class="row">
          <label>Color</label>
          <input type="text" id="color" placeholder="(optional)" />
        </div>
        <div class="row">
          <label>Title</label>
          <input type="text" id="title" placeholder="(optional)" style="width:280px;" />
        </div>
        <div class="hint">Requires {:vega_lite, "~> 0.1"} in Mix.install</div>
      `;

      ctx.root.appendChild(styleEl);
      ctx.root.appendChild(container);

      const fields = ["binding", "chart_type", "x", "y", "color", "title"];
      fields.forEach(f => {
        const el = container.querySelector("#" + f);
        el.value = payload[f] || "";
        el.addEventListener("change", (e) => {
          ctx.pushEvent("update_field", { field: f, value: e.target.value });
        });
      });

      ctx.handleEvent("update", (data) => {
        fields.forEach(f => {
          container.querySelector("#" + f).value = data[f] || "";
        });
      });
    }
    """
  end
end
