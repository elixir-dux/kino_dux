defmodule KinoDux.ProgressTest do
  use ExUnit.Case, async: true

  test "new/0 returns a Progress struct with a frame" do
    progress = KinoDux.Progress.new()
    assert %KinoDux.Progress{} = progress
    assert %Kino.Frame{} = progress.frame
    assert progress.state == :idle
    assert progress.n_workers == 0
    assert progress.workers_done == 0
    assert is_reference(progress.ref)
  end
end
