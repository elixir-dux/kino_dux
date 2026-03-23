defimpl Kino.Render, for: Dux do
  def to_livebook(%Dux{source: {:table, _table_ref}} = dux) do
    dux
    |> Kino.DataTable.new(name: "Dux Result", sorting_enabled: true)
    |> Kino.Render.to_livebook()
  end

  def to_livebook(%Dux{} = dux) do
    KinoDux.LazyView.render(dux)
    |> Kino.Render.to_livebook()
  end
end
