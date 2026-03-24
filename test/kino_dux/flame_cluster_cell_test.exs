defmodule KinoDux.FlameClusterCellTest do
  use ExUnit.Case, async: true

  describe "to_source/1" do
    test "generates fly backend config" do
      source =
        KinoDux.FlameClusterCell.to_source(%{
          "backend" => "fly",
          "max_workers" => "10",
          "cpus" => "4",
          "memory_mb" => "16384",
          "idle_minutes" => "5",
          "gpu" => "",
          "pool_name" => ""
        })

      assert source =~ "Dux.Flame.start_pool"
      assert source =~ "FLAME.FlyBackend"
      assert source =~ "FLY_API_TOKEN"
      assert source =~ "cpus: 4"
      assert source =~ "memory_mb: 16384"
      assert source =~ "max: 10"
      assert source =~ "idle_shutdown_after: :timer.minutes(5)"
    end

    test "includes gpu_kind when specified" do
      source =
        KinoDux.FlameClusterCell.to_source(%{
          "backend" => "fly",
          "max_workers" => "5",
          "cpus" => "8",
          "memory_mb" => "32768",
          "idle_minutes" => "10",
          "gpu" => "a100-40gb",
          "pool_name" => ""
        })

      assert source =~ ~s(gpu_kind: "a100-40gb")
    end

    test "includes pool name when specified" do
      source =
        KinoDux.FlameClusterCell.to_source(%{
          "backend" => "fly",
          "max_workers" => "3",
          "cpus" => "2",
          "memory_mb" => "4096",
          "idle_minutes" => "5",
          "gpu" => "",
          "pool_name" => ":my_pool"
        })

      assert source =~ "name: :my_pool"
    end

    test "generates local backend config" do
      source =
        KinoDux.FlameClusterCell.to_source(%{
          "backend" => "local",
          "max_workers" => "4",
          "cpus" => "2",
          "memory_mb" => "8192",
          "idle_minutes" => "3",
          "gpu" => "",
          "pool_name" => ""
        })

      assert source =~ "FLAME.LocalBackend"
      refute source =~ "FLY_API_TOKEN"
    end
  end
end
