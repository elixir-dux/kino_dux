defmodule KinoDux.DistributedStats do
  @moduledoc false

  # Renders execution metadata for distributed Dux queries.
  # Shows node count, merge strategy, total duration, and per-node breakdown.

  def render(%{distributed: true} = meta) do
    header = format_header(meta)
    worker_details = format_worker_stats(meta[:worker_stats] || [])

    """
    <div style="font-family:'Fira Code',monospace;font-size:12px;background:#1a1918;color:#e8e4de;padding:12px 16px;border-radius:6px 6px 0 0;border:1px solid #2a2724;border-bottom:none;">
      #{header}
      #{worker_details}
    </div>
    """
  end

  def render(_meta), do: ""

  defp format_header(meta) do
    n_nodes = meta[:n_nodes] || 0
    n_workers = meta[:n_workers] || 0
    duration_str = if meta[:total_duration_ms], do: format_ms(meta[:total_duration_ms]), else: "—"
    workers_s = if n_workers != 1, do: "s", else: ""
    nodes_s = if n_nodes != 1, do: "s", else: ""
    merge_str = format_merge(meta[:merge_strategy])

    """
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px;">
      <span style="width:8px;height:8px;border-radius:50%;background:#5eb88a;display:inline-block;"></span>
      <span style="color:#5eb88a;font-weight:500;">Distributed</span>
      <span style="color:#6b665e;">#{n_workers} worker#{workers_s} across #{n_nodes} node#{nodes_s}</span>
      <span style="color:#6b665e;">&middot;</span>
      <span style="color:#9b9588;">#{duration_str}</span>
      <span style="color:#6b665e;">&middot;</span>
      <span style="color:#6b665e;">merge: #{merge_str}</span>
    </div>
    """
  end

  defp format_worker_stats([]), do: ""

  defp format_worker_stats(stats) do
    max_duration = stats |> Enum.map(&(&1[:duration_ms] || 0)) |> Enum.max(fn -> 0 end)

    rows =
      stats
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {stat, i} ->
        node_short = stat[:node] |> to_string() |> short_node_name() |> escape()
        dur_ms = stat[:duration_ms] || 0
        duration = format_ms(dur_ms)
        ipc_kb = div(stat[:ipc_bytes] || 0, 1024)

        ipc_str =
          if ipc_kb > 1024,
            do: "#{Float.round(ipc_kb / 1024, 1)} MB",
            else: "#{ipc_kb} KB"

        # Highlight the slowest worker
        dur_style =
          if dur_ms == max_duration and length(stats) > 1,
            do: ~s[style="color:#d6956b;"],
            else: ""

        ~s[<div>Worker #{i}: <span style="color:#6ba3d6;">#{node_short}</span> &middot; <span #{dur_style}>#{duration}</span> &middot; #{ipc_str}</div>]
      end)

    ~s[<div style="font-size:11px;color:#6b665e;margin-top:4px;">#{rows}</div>]
  end

  defp format_merge(:streaming), do: "streaming"
  defp format_merge(:batch), do: "batch"
  defp format_merge(_), do: "—"

  defp short_node_name(name) do
    case String.split(name, "@") do
      [prefix, _] -> prefix
      _ -> name
    end
  end

  defp format_ms(ms) when ms < 1000, do: "#{ms}ms"
  defp format_ms(ms), do: "#{Float.round(ms / 1000, 1)}s"

  defp escape(text) do
    text
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
