defmodule KinoDux.LazyView do
  @moduledoc false

  # Renders a lazy (uncomputed) %Dux{} pipeline as rich HTML in Livebook.
  # Shows source, operations list, and generated SQL.

  def render(%Dux{} = dux) do
    source_html = format_source(dux.source)
    ops_html = format_ops(dux.ops)
    sql_html = format_sql(dux)

    dist_html =
      if dux.workers do
        ~s(<div style="margin-top:8px;color:#5eb88a;">distributed: #{length(dux.workers)} workers</div>)
      else
        ""
      end

    html = """
    <div style="font-family:'Fira Code',monospace;font-size:13px;background:#1a1918;color:#e8e4de;padding:16px;border-radius:6px;border:1px solid #2a2724;">
      <div style="font-size:11px;letter-spacing:0.1em;text-transform:uppercase;color:#6b665e;margin-bottom:8px;">Dux Pipeline (lazy)</div>
      <div style="margin-bottom:8px;">
        <span style="color:#9b9588;">Source:</span>
        <span style="color:#d4845a;">#{source_html}</span>
      </div>
      #{dist_html}
      #{ops_html}
      #{sql_html}
    </div>
    """

    Kino.HTML.new(html)
  end

  defp format_source({:parquet, path}), do: "parquet: #{escape(truncate(path, 60))}"
  defp format_source({:parquet, path, _opts}), do: "parquet: #{escape(truncate(path, 60))}"
  defp format_source({:csv, path, _opts}), do: "csv: #{escape(truncate(path, 60))}"
  defp format_source({:ndjson, path, _opts}), do: "ndjson: #{escape(truncate(path, 60))}"
  defp format_source({:sql, sql}), do: "sql: #{escape(truncate(sql, 60))}"
  defp format_source({:attached, db, table}), do: "attached: #{db}.#{escape(table)}"
  defp format_source({:attached, db, table, _opts}), do: "attached: #{db}.#{escape(table)}"
  defp format_source({:list, rows}), do: "list (#{length(rows)} rows)"
  defp format_source({:table, _ref}), do: "materialized table"
  defp format_source(nil), do: "empty"
  defp format_source(other), do: escape(inspect(other))

  defp format_ops([]), do: ""

  defp format_ops(ops) do
    items =
      ops
      |> Enum.with_index(1)
      |> Enum.map(fn {op, i} ->
        desc = describe_op(op)

        ~s(<div style="padding:2px 0;"><span style="color:#6b665e;">#{i}.</span> <span style="color:#6ba3d6;">#{escape(desc)}</span></div>)
      end)

    """
    <div style="margin-bottom:8px;">
      <span style="color:#9b9588;">Operations:</span>
      <div style="margin-left:12px;margin-top:4px;">#{Enum.join(items)}</div>
    </div>
    """
  end

  defp format_sql(%Dux{} = dux) do
    sql =
      try do
        Dux.sql_preview(dux, pretty: true)
      rescue
        _ -> nil
      end

    case sql do
      nil ->
        ""

      sql ->
        """
        <details style="margin-top:8px;">
          <summary style="cursor:pointer;color:#9b9588;font-size:12px;">Generated SQL</summary>
          <pre style="margin-top:6px;padding:10px;background:#0c0b0a;border-radius:4px;border:1px solid #2a2724;overflow-x:auto;font-size:12px;color:#e8e4de;">#{escape(sql)}</pre>
        </details>
        """
    end
  end

  defp describe_op({:filter, _ast}), do: "filter"
  defp describe_op({:mutate, bindings}), do: "mutate: #{binding_names(bindings)}"
  defp describe_op({:select, cols}), do: "select: #{col_names(cols)}"
  defp describe_op({:discard, cols}), do: "discard: #{col_names(cols)}"
  defp describe_op({:group_by, cols}), do: "group_by: #{col_names(cols)}"
  defp describe_op({:summarise, bindings}), do: "summarise: #{binding_names(bindings)}"
  defp describe_op({:sort_by, _}), do: "sort_by"
  defp describe_op({:head, n}), do: "head(#{n})"
  defp describe_op({:join, _kind, _right, _opts}), do: "join"
  defp describe_op({:distinct, _}), do: "distinct"
  defp describe_op({:concat_rows, _}), do: "concat_rows"
  defp describe_op({:pivot_wider, _}), do: "pivot_wider"
  defp describe_op({:pivot_longer, _}), do: "pivot_longer"
  defp describe_op({:window, _}), do: "window"
  defp describe_op({:rename, mapping}), do: "rename: #{binding_names(mapping)}"
  defp describe_op({:drop_nil, cols}), do: "drop_nil: #{col_names(cols)}"
  defp describe_op({:slice, offset, len}), do: "slice(#{offset}, #{len})"
  defp describe_op({:summarise_with, bindings}), do: "summarise: #{binding_names(bindings)}"
  defp describe_op({:mutate_with, bindings}), do: "mutate: #{binding_names(bindings)}"
  defp describe_op({:filter_with, _}), do: "filter (raw SQL)"
  defp describe_op(:ungroup), do: "ungroup"
  defp describe_op({:asof_join, _, _, _, _, _}), do: "asof_join"
  defp describe_op({:join, _, _, _, _}), do: "join"
  defp describe_op({:insert_into, _target, _opts}), do: "insert_into"
  defp describe_op({:pivot_wider, _, _, _}), do: "pivot_wider"
  defp describe_op({:pivot_longer, _, _, _}), do: "pivot_longer"
  defp describe_op({name, _}), do: to_string(name)
  defp describe_op(other), do: inspect(other)

  defp binding_names(bindings) when is_list(bindings) do
    Enum.map_join(bindings, ", ", fn
      {name, _ast} -> to_string(name)
      name when is_atom(name) -> to_string(name)
      other -> inspect(other)
    end)
  end

  defp binding_names(_), do: "..."

  defp col_names(cols) when is_list(cols) do
    Enum.map_join(cols, ", ", &to_string/1)
  end

  defp col_names(col) when is_atom(col), do: to_string(col)
  defp col_names(_), do: "..."

  defp truncate(s, max) do
    if String.length(s) > max do
      String.slice(s, 0, max - 1) <> "…"
    else
      s
    end
  end

  defp escape(text) do
    text
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
