defmodule KinoDux.LazyViewTest do
  use ExUnit.Case, async: true

  # LazyView builds HTML strings and wraps them in Kino.HTML.
  # We test the HTML generation by extracting the internal build functions.
  # Since format_source/1 and friends are private, we test through render/1
  # and use :erlang.term_to_binary to capture the JS init data.

  # We can access the HTML via Kino.JS.DataStore — but that's complex.
  # Instead, we make LazyView's HTML generation testable by extracting
  # the html string building into a public function.

  # For now, test that render/1 doesn't crash for all source types and
  # verify code generation in the smart cells (which are the user-facing API).

  describe "render/1 succeeds for all source types" do
    test "parquet source" do
      dux = %Dux{
        source: {:parquet, "data.parquet", []},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "parquet source without opts" do
      dux = %Dux{source: {:parquet, "data.parquet"}, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end

    test "csv source" do
      dux = %Dux{source: {:csv, "sales.csv", []}, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end

    test "ndjson source" do
      dux = %Dux{
        source: {:ndjson, "events.ndjson", []},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "sql source" do
      dux = %Dux{source: {:sql, "SELECT 1"}, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end

    test "attached database source" do
      dux = %Dux{
        source: {:attached, :warehouse, "public.customers"},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "attached database source with options" do
      dux = %Dux{
        source: {:attached, :pg, "orders", partition_by: :id},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "list source" do
      dux = %Dux{
        source: {:list, [%{a: 1}, %{a: 2}]},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "nil source" do
      dux = %Dux{source: nil, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end

    test "unknown source type" do
      dux = %Dux{source: {:unknown, "wat"}, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end
  end

  describe "render/1 with operations" do
    test "renders all known op types without crashing" do
      ops = [
        {:filter, {:>, :amount, 100}},
        {:mutate, [revenue: {:*, :price, :qty}]},
        {:select, [:a, :b]},
        {:discard, [:c]},
        {:group_by, [:a]},
        {:summarise, [total: {:sum, :b}]},
        {:sort_by, :x},
        {:head, 10},
        {:distinct, :all},
        {:join, :inner, nil, []},
        {:pivot_wider, []},
        {:pivot_longer, []},
        {:concat_rows, []},
        {:window, []},
        {:mutate_with, "ROW_NUMBER()"},
        {:filter_with, "x > 1"},
        {:asof_join, :left, nil, []},
        {:insert_into, "table", []}
      ]

      dux = %Dux{
        source: {:parquet, "d.parquet", []},
        ops: ops,
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "renders empty ops list" do
      dux = %Dux{source: {:parquet, "d.parquet", []}, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end
  end

  describe "render/1 with distribution" do
    test "renders workers info" do
      dux = %Dux{
        source: {:parquet, "d.parquet", []},
        ops: [],
        names: [],
        dtypes: %{},
        groups: [],
        workers: [:w1, :w2, :w3]
      }

      assert KinoDux.LazyView.render(dux)
    end
  end

  describe "render/1 adversarial inputs" do
    test "handles XSS in source path" do
      dux = %Dux{
        source: {:parquet, "<script>alert('xss')</script>", []},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "handles very long source path" do
      dux = %Dux{
        source: {:parquet, String.duplicate("a", 1000), []},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "handles empty string source path" do
      dux = %Dux{source: {:parquet, "", []}, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end

    test "handles unicode in source path" do
      dux = %Dux{
        source: {:parquet, "données/données.parquet", []},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      assert KinoDux.LazyView.render(dux)
    end

    test "handles empty list source" do
      dux = %Dux{source: {:list, []}, ops: [], names: [], dtypes: %{}, groups: []}
      assert KinoDux.LazyView.render(dux)
    end
  end
end
