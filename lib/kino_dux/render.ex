defimpl Kino.Render, for: Dux do
  def to_livebook(%Dux{source: {:table, _table_ref}} = dux) do
    meta = Map.get(dux, :meta)

    if is_map(meta) and meta[:distributed] do
      stats_html = KinoDux.DistributedStats.render(meta)
      table = Kino.DataTable.new(dux, name: "Dux Result", sorting_enabled: true)

      Kino.Layout.grid([Kino.HTML.new(stats_html), table], columns: 1)
      |> Kino.Render.to_livebook()
    else
      dux
      |> Kino.DataTable.new(name: "Dux Result", sorting_enabled: true)
      |> Kino.Render.to_livebook()
    end
  end

  def to_livebook(%Dux{} = dux) do
    KinoDux.LazyView.render(dux)
    |> Kino.Render.to_livebook()
  end
end
