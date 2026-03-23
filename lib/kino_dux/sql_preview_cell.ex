defmodule KinoDux.SQLPreviewCell do
  @moduledoc false

  # Smart Cell that shows generated SQL for a %Dux{} binding.
  # The user picks a Dux variable from a dropdown, and the cell
  # renders the SQL that would be executed on compute.

  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Dux SQL Preview"

  @impl true
  def init(attrs, ctx) do
    binding = attrs["binding"] || ""
    {:ok, assign(ctx, binding: binding)}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{binding: ctx.assigns.binding}, ctx}
  end

  @impl true
  def handle_event("update_binding", %{"binding" => binding}, ctx) do
    broadcast_event(ctx, "update", %{binding: binding})
    {:noreply, assign(ctx, binding: binding)}
  end

  @impl true
  def to_attrs(ctx) do
    %{"binding" => ctx.assigns.binding}
  end

  @impl true
  def to_source(attrs) do
    binding = attrs["binding"]

    if binding != "" do
      quote =
        """
        #{binding}
        |> Dux.sql_preview(pretty: true)
        |> IO.puts()
        """

      String.trim(quote)
    else
      ""
    end
  end

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500&display=swap");

      const container = document.createElement("div");
      container.style.fontFamily = "'Fira Code', monospace";
      container.style.fontSize = "13px";
      container.style.padding = "12px";

      const label = document.createElement("label");
      label.textContent = "Dux binding: ";
      label.style.color = "#9b9588";

      const input = document.createElement("input");
      input.type = "text";
      input.value = payload.binding || "";
      input.placeholder = "e.g. pipeline";
      input.style.background = "#1a1918";
      input.style.border = "1px solid #2a2724";
      input.style.borderRadius = "4px";
      input.style.padding = "4px 8px";
      input.style.color = "#e8e4de";
      input.style.fontFamily = "'Fira Code', monospace";
      input.style.fontSize = "13px";
      input.style.marginLeft = "8px";
      input.style.width = "200px";

      input.addEventListener("change", (e) => {
        ctx.pushEvent("update_binding", { binding: e.target.value });
      });

      container.appendChild(label);
      container.appendChild(input);
      ctx.root.appendChild(container);

      ctx.handleEvent("update", (data) => {
        input.value = data.binding;
      });
    }
    """
  end
end
