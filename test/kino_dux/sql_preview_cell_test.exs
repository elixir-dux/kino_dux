defmodule KinoDux.SQLPreviewCellTest do
  use ExUnit.Case, async: true

  describe "to_source/1" do
    test "generates sql_preview code for a binding" do
      source = KinoDux.SQLPreviewCell.to_source(%{"binding" => "pipeline"})
      assert source =~ "pipeline"
      assert source =~ "Dux.sql_preview"
      assert source =~ "pretty: true"
      assert source =~ "IO.puts"
    end

    test "returns empty string for empty binding" do
      assert KinoDux.SQLPreviewCell.to_source(%{"binding" => ""}) == ""
    end

    test "generates code even for nil binding (truthy check)" do
      # nil is not == "", so it generates code — this matches the actual behavior
      source = KinoDux.SQLPreviewCell.to_source(%{"binding" => nil})
      assert source =~ "Dux.sql_preview"
    end
  end
end
