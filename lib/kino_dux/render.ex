defimpl Kino.Render, for: Dux do
  def to_livebook(%Dux{source: {:table, _table_ref}, workers: workers} = dux)
      when is_list(workers) and workers != [] do
    n_nodes = workers |> Enum.map(&node/1) |> Enum.uniq() |> length()
    name = "Dux Result — distributed across #{n_nodes} node#{if n_nodes != 1, do: "s"}"

    dux
    |> Kino.DataTable.new(name: name, sorting_enabled: true)
    |> Kino.Render.to_livebook()
  end

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
