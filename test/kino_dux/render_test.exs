defmodule KinoDux.RenderTest do
  use ExUnit.Case, async: true

  describe "Kino.Render for %Dux{}" do
    test "lazy pipeline renders via LazyView (returns JS output)" do
      dux = %Dux{
        source: {:parquet, "test.parquet", []},
        ops: [],
        names: [],
        dtypes: %{},
        groups: []
      }

      result = Kino.Render.to_livebook(dux)
      assert result.type == :js
    end

    test "lazy pipeline with ops renders successfully" do
      dux = %Dux{
        source: {:parquet, "test.parquet", []},
        ops: [{:filter, {:>, :x, 1}}, {:head, 5}],
        names: [],
        dtypes: %{},
        groups: []
      }

      result = Kino.Render.to_livebook(dux)
      assert result.type == :js
    end
  end
end
