defmodule KinoDux.FlameClusterCell do
  @moduledoc false

  # Smart Cell for configuring and managing a FLAME pool for Dux.
  # Generates Dux.Flame.start_pool/1 code with chosen backend,
  # machine size, and worker limits.

  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Dux FLAME Cluster"

  @impl true
  def init(attrs, ctx) do
    fields = %{
      backend: attrs["backend"] || "fly",
      max_workers: attrs["max_workers"] || "10",
      cpus: attrs["cpus"] || "4",
      memory_mb: attrs["memory_mb"] || "16384",
      idle_minutes: attrs["idle_minutes"] || "5",
      gpu: attrs["gpu"] || "",
      pool_name: attrs["pool_name"] || ""
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
    backend = attrs["backend"]
    max = attrs["max_workers"]
    cpus = attrs["cpus"]
    memory = attrs["memory_mb"]
    idle = attrs["idle_minutes"]
    gpu = attrs["gpu"]
    pool_name = attrs["pool_name"]

    backend_mod = backend_module(backend)
    backend_opts = backend_opts(backend, cpus, memory, gpu)

    backend_line =
      if backend_opts == "" do
        "  backend: #{backend_mod}"
      else
        "  backend: {#{backend_mod}, [#{backend_opts}]}"
      end

    opts = [
      backend_line,
      "  max: #{max}",
      "  idle_shutdown_after: :timer.minutes(#{idle})"
    ]

    opts =
      if pool_name != "" do
        ["  name: #{pool_name}" | opts]
      else
        opts
      end

    "Dux.Flame.start_pool(\n#{Enum.join(opts, ",\n")}\n)"
  end

  defp backend_module("fly"), do: "FLAME.FlyBackend"
  defp backend_module("local"), do: "FLAME.LocalBackend"
  defp backend_module(_), do: "FLAME.FlyBackend"

  defp backend_opts("fly", cpus, memory, gpu) do
    opts = [
      ~s[token: System.fetch_env!("FLY_API_TOKEN")],
      "cpus: #{cpus}",
      "memory_mb: #{memory}"
    ]

    opts = if gpu != "", do: opts ++ [~s[gpu_kind: "#{gpu}"]], else: opts
    Enum.join(opts, ", ")
  end

  defp backend_opts("local", _cpus, _memory, _gpu), do: ""
  defp backend_opts(_, cpus, memory, _gpu), do: "cpus: #{cpus}, memory_mb: #{memory}"

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500&display=swap");

      const style = `
        .dux-flame { font-family: 'Fira Code', monospace; font-size: 13px; padding: 12px; }
        .dux-flame label { color: #9b9588; display: inline-block; width: 100px; }
        .dux-flame input, .dux-flame select {
          background: #1a1918; border: 1px solid #2a2724; border-radius: 4px;
          padding: 4px 8px; color: #e8e4de; font-family: 'Fira Code', monospace;
          font-size: 13px; margin-left: 8px;
        }
        .dux-flame select { width: 120px; }
        .dux-flame input { width: 120px; }
        .dux-flame .row { margin-bottom: 8px; display: flex; align-items: center; }
        .dux-flame .section { font-size: 11px; letter-spacing: 0.1em; text-transform: uppercase;
          color: #6b665e; margin-bottom: 8px; margin-top: 12px; }
        .dux-flame .hint { font-size: 11px; color: #6b665e; margin-left: 112px; }
      `;

      const styleEl = document.createElement("style");
      styleEl.textContent = style;

      const container = document.createElement("div");
      container.className = "dux-flame";

      container.innerHTML = `
        <div class="section">FLAME Pool Configuration</div>
        <div class="row">
          <label>Backend</label>
          <select id="backend">
            <option value="fly">Fly.io</option>
            <option value="local">Local</option>
          </select>
        </div>
        <div class="row">
          <label>Max workers</label>
          <input type="number" id="max_workers" min="1" max="100" />
        </div>
        <div class="row">
          <label>CPUs</label>
          <input type="number" id="cpus" min="1" max="32" />
        </div>
        <div class="row">
          <label>Memory (MB)</label>
          <input type="number" id="memory_mb" min="256" step="1024" style="width:100px;" />
        </div>
        <div class="row">
          <label>Idle timeout</label>
          <input type="number" id="idle_minutes" min="1" style="width:60px;" />
          <span style="color:#6b665e;margin-left:8px;">min</span>
        </div>
        <div class="row">
          <label>GPU</label>
          <input type="text" id="gpu" placeholder="(optional)" style="width:120px;" />
          <span class="hint" style="margin-left:8px;">e.g. l40s, a100-40gb</span>
        </div>
        <div class="row">
          <label>Pool name</label>
          <input type="text" id="pool_name" placeholder="(optional)" style="width:160px;" />
        </div>
      `;

      ctx.root.appendChild(styleEl);
      ctx.root.appendChild(container);

      const fields = ["backend", "max_workers", "cpus", "memory_mb", "idle_minutes", "gpu", "pool_name"];
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
