defmodule KinoDux.ChartCellTest do
  use ExUnit.Case, async: true

  describe "to_source/1" do
    test "generates VegaLite bar chart code" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "bar",
          "x" => "category",
          "y" => "count",
          "color" => "",
          "title" => ""
        })

      assert source =~ "df"
      assert source =~ "Dux.compute()"
      assert source =~ "VegaLite.new()"
      assert source =~ "mark(:bar)"
      assert source =~ ~s[encode_field(:x, "category"]
      assert source =~ ~s[encode_field(:y, "count"]
      assert source =~ "type: :nominal"
      assert source =~ "type: :quantitative"
    end

    test "generates line chart with temporal x axis" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "line",
          "x" => "date",
          "y" => "value",
          "color" => "",
          "title" => ""
        })

      assert source =~ "mark(:line)"
      assert source =~ "type: :temporal"
    end

    test "includes color encoding when specified" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "point",
          "x" => "x",
          "y" => "y",
          "color" => "group",
          "title" => ""
        })

      assert source =~ ~s[encode_field(:color, "group")]
    end

    test "includes title when specified" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "bar",
          "x" => "x",
          "y" => "y",
          "color" => "",
          "title" => "My Chart"
        })

      assert source =~ ~s[title: "My Chart"]
    end

    test "returns empty string when binding is empty" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "",
          "chart_type" => "bar",
          "x" => "x",
          "y" => "y",
          "color" => "",
          "title" => ""
        })

      assert source == ""
    end

    test "returns empty string when x is empty" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "bar",
          "x" => "",
          "y" => "y",
          "color" => "",
          "title" => ""
        })

      assert source == ""
    end

    test "returns empty string when y is empty" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "bar",
          "x" => "x",
          "y" => "",
          "color" => "",
          "title" => ""
        })

      assert source == ""
    end

    test "generates area chart" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "area",
          "x" => "x",
          "y" => "y",
          "color" => "",
          "title" => ""
        })

      assert source =~ "mark(:area)"
    end

    test "defaults unknown chart type to bar" do
      source =
        KinoDux.ChartCell.to_source(%{
          "binding" => "df",
          "chart_type" => "pie",
          "x" => "x",
          "y" => "y",
          "color" => "",
          "title" => ""
        })

      assert source =~ "mark(:bar)"
    end
  end
end
