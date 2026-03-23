defimpl Kino.Render, for: Dux.Graph do
  def to_livebook(%Dux.Graph{} = graph) do
    info = [
      {"Vertex ID column", graph.vertex_id},
      {"Edge columns", "#{graph.edge_src} → #{graph.edge_dst}"}
    ]

    info =
      if graph.workers do
        info ++ [{"Distribution", "#{length(graph.workers)} workers"}]
      else
        info
      end

    rows =
      Enum.map(info, fn {label, value} ->
        ~s(<tr><td style="font-weight:600;padding:4px 12px 4px 0;color:#9b7fc9;">#{label}</td>) <>
          ~s(<td style="padding:4px 0;">#{value}</td></tr>)
      end)

    html = """
    <div style="font-family:monospace;font-size:13px;background:#1a1918;color:#e8e4de;padding:16px;border-radius:6px;border:1px solid #2a2724;">
      <div style="font-size:11px;letter-spacing:0.1em;text-transform:uppercase;color:#6b665e;margin-bottom:8px;">Dux.Graph</div>
      <table>#{Enum.join(rows)}</table>
    </div>
    """

    Kino.HTML.new(html) |> Kino.Render.to_livebook()
  end
end
