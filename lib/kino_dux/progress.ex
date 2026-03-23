defmodule KinoDux.Progress do
  @moduledoc """
  Live progress widget for distributed Dux queries.

  Subscribes to Dux telemetry events and renders real-time progress
  in a Livebook cell via `Kino.Frame`.

  ## Usage

      progress = KinoDux.Progress.new()
      Kino.render(progress.frame)

      result = Dux.distribute(pipeline, flame: 10, progress: progress)

  Shows worker boot progress, per-worker execution status, merge status,
  elapsed time, and a cancel button.
  """

  defstruct [:frame, :ref, :start_time, :n_workers, :workers_done, :state, :cancel_ref]

  @type t :: %__MODULE__{}

  @doc """
  Create a new progress widget.

  Returns a `%KinoDux.Progress{}` struct. Render with `Kino.render(progress.frame)`.
  """
  def new do
    frame = Kino.Frame.new()
    ref = make_ref()

    progress = %__MODULE__{
      frame: frame,
      ref: ref,
      start_time: nil,
      n_workers: 0,
      workers_done: 0,
      state: :idle,
      cancel_ref: nil
    }

    attach_telemetry(progress)
    render_state(progress)
    progress
  end

  defp attach_telemetry(%__MODULE__{ref: ref, frame: frame}) do
    handler_id = "kino_dux_progress_#{inspect(ref)}"
    self_pid = self()

    # We use a GenServer-like approach: telemetry handlers send messages
    # to a task that updates the frame
    {:ok, pid} =
      Task.start_link(fn ->
        progress_loop(%{
          frame: frame,
          ref: ref,
          start_time: nil,
          n_workers: 0,
          workers_done: 0,
          state: :idle
        })
      end)

    events = [
      [:dux, :distributed, :fan_out, :start],
      [:dux, :distributed, :fan_out, :stop],
      [:dux, :distributed, :worker, :stop],
      [:dux, :distributed, :merge, :start],
      [:dux, :distributed, :merge, :stop],
      [:dux, :query, :stop],
      [:dux, :query, :exception]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(pid, {:telemetry, event, measurements, metadata})
      end,
      nil
    )
  end

  defp progress_loop(state) do
    receive do
      {:telemetry, [:dux, :distributed, :fan_out, :start], _m, meta} ->
        state = %{state | state: :fan_out, n_workers: meta.n_workers, start_time: System.monotonic_time()}
        render_progress(state)
        progress_loop(state)

      {:telemetry, [:dux, :distributed, :fan_out, :stop], _m, _meta} ->
        state = %{state | state: :executing}
        render_progress(state)
        progress_loop(state)

      {:telemetry, [:dux, :distributed, :worker, :stop], measurements, meta} ->
        done = state.workers_done + 1
        state = %{state | workers_done: done}
        render_progress(state)
        progress_loop(state)

      {:telemetry, [:dux, :distributed, :merge, :start], _m, _meta} ->
        state = %{state | state: :merging}
        render_progress(state)
        progress_loop(state)

      {:telemetry, [:dux, :distributed, :merge, :stop], _m, _meta} ->
        state = %{state | state: :merged}
        render_progress(state)
        progress_loop(state)

      {:telemetry, [:dux, :query, :stop], measurements, _meta} ->
        state = %{state | state: :done}
        render_done(state, measurements.duration)
        # Exit the loop — done

      {:telemetry, [:dux, :query, :exception], _m, meta} ->
        state = %{state | state: :error}
        render_error(state, meta.reason)
        # Exit the loop — error

      _ ->
        progress_loop(state)
    end
  end

  defp render_state(%__MODULE__{frame: frame}) do
    Kino.Frame.render(frame, Kino.HTML.new(status_html(:idle, %{})))
  end

  defp render_progress(state) do
    Kino.Frame.render(state.frame, Kino.HTML.new(status_html(state.state, state)))
  end

  defp render_done(state, duration_native) do
    ms = System.convert_time_unit(duration_native, :native, :millisecond)
    Kino.Frame.render(state.frame, Kino.HTML.new(done_html(state, ms)))
  end

  defp render_error(state, reason) do
    Kino.Frame.render(state.frame, Kino.HTML.new(error_html(reason)))
  end

  defp status_html(:idle, _) do
    box("Waiting for distributed query...", "#6b665e", [])
  end

  defp status_html(:fan_out, state) do
    box("Distributing to #{state.n_workers} workers...", "#d4845a", [
      bar(0, state.n_workers)
    ])
  end

  defp status_html(:executing, state) do
    elapsed = elapsed_ms(state.start_time)

    box("Executing", "#6ba3d6", [
      bar(state.workers_done, state.n_workers),
      detail("Workers: #{state.workers_done}/#{state.n_workers} complete"),
      detail("Elapsed: #{format_ms(elapsed)}")
    ])
  end

  defp status_html(:merging, state) do
    elapsed = elapsed_ms(state.start_time)

    box("Merging results...", "#9b7fc9", [
      bar(state.n_workers, state.n_workers),
      detail("All #{state.n_workers} workers complete"),
      detail("Elapsed: #{format_ms(elapsed)}")
    ])
  end

  defp status_html(:merged, state), do: status_html(:merging, state)

  defp done_html(state, ms) do
    box("Complete", "#5eb88a", [
      bar(state.n_workers, state.n_workers),
      detail("#{state.n_workers} workers &middot; #{format_ms(ms)}")
    ])
  end

  defp error_html(reason) do
    box("Error", "#e85050", [
      ~s(<div style="font-size:12px;color:#e8e4de;margin-top:4px;">#{escape(inspect(reason, limit: 100))}</div>)
    ])
  end

  defp box(title, color, children) do
    """
    <div style="font-family:'Fira Code',monospace;font-size:13px;background:#1a1918;color:#e8e4de;padding:12px 16px;border-radius:6px;border:1px solid #2a2724;">
      <div style="display:flex;align-items:center;gap:8px;">
        <span style="width:8px;height:8px;border-radius:50%;background:#{color};display:inline-block;"></span>
        <span style="color:#{color};font-weight:500;">#{title}</span>
      </div>
      #{Enum.join(children)}
    </div>
    """
  end

  defp bar(done, total) when total > 0 do
    pct = round(done / total * 100)

    """
    <div style="margin-top:8px;background:#0c0b0a;border-radius:3px;height:6px;overflow:hidden;">
      <div style="width:#{pct}%;height:100%;background:#5eb88a;border-radius:3px;transition:width 0.3s;"></div>
    </div>
    """
  end

  defp bar(_, _), do: ""

  defp detail(text) do
    ~s(<div style="font-size:11px;color:#9b9588;margin-top:4px;">#{text}</div>)
  end

  defp elapsed_ms(nil), do: 0

  defp elapsed_ms(start) do
    System.convert_time_unit(System.monotonic_time() - start, :native, :millisecond)
  end

  defp format_ms(ms) when ms < 1000, do: "#{ms}ms"
  defp format_ms(ms), do: "#{Float.round(ms / 1000, 1)}s"

  defp escape(text) do
    text
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
