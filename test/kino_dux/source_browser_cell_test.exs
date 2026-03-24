defmodule KinoDux.SourceBrowserCellTest do
  use ExUnit.Case, async: true

  describe "to_source/1" do
    test "generates from_parquet code" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "parquet",
          "path" => "data.parquet",
          "variable" => "df"
        })

      assert source == ~s[df = Dux.from_parquet("data.parquet")]
    end

    test "generates from_csv code without options" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "csv",
          "path" => "data.csv",
          "variable" => "df",
          "csv_delimiter" => ",",
          "csv_header" => true
        })

      assert source == ~s[df = Dux.from_csv("data.csv")]
    end

    test "generates from_csv code with custom delimiter" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "csv",
          "path" => "data.tsv",
          "variable" => "df",
          "csv_delimiter" => "\t",
          "csv_header" => true
        })

      assert source =~ "delimiter:"
      assert source =~ "data.tsv"
    end

    test "generates from_csv code with header false" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "csv",
          "path" => "data.csv",
          "variable" => "df",
          "csv_delimiter" => ",",
          "csv_header" => false
        })

      assert source =~ "header: false"
    end

    test "generates from_ndjson code" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "ndjson",
          "path" => "events.ndjson",
          "variable" => "events"
        })

      assert source == ~s[events = Dux.from_ndjson("events.ndjson")]
    end

    test "generates from_query code for sql type" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "sql",
          "path" => "SELECT * FROM t",
          "variable" => "df"
        })

      assert source == ~s[df = Dux.from_query("SELECT * FROM t")]
    end

    test "generates from_attached code" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "attached",
          "path" => "warehouse.public.customers",
          "variable" => "customers"
        })

      assert source == ~s[customers = Dux.from_attached(:warehouse, "public.customers")]
    end

    test "generates comment for malformed attached path" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "attached",
          "path" => "no_dot_here",
          "variable" => "df"
        })

      assert source =~ "# Specify as db_name.table_name"
    end

    test "returns empty string when variable is empty" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "parquet",
          "path" => "data.parquet",
          "variable" => ""
        })

      assert source == ""
    end

    test "returns empty string when path is empty" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "parquet",
          "path" => "",
          "variable" => "df"
        })

      assert source == ""
    end

    test "escapes double quotes in paths" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "parquet",
          "path" => ~s(path"with"quotes),
          "variable" => "df"
        })

      assert source =~ ~s(\\")
      refute source =~ ~s(path"with)
    end

    test "returns empty string for unknown source type" do
      source =
        KinoDux.SourceBrowserCell.to_source(%{
          "source_type" => "unknown",
          "path" => "data",
          "variable" => "df"
        })

      assert source == ""
    end
  end
end
