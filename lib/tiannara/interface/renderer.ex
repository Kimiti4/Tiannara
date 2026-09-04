defmodule Tiannara.Interface.Renderer do
  @moduledoc """
  Rendering contract for the human interface. The ViewModel is renderer-
  agnostic, so presentation can be replaced without touching data logic
  (Modularity, Replaceability).

  Implementations:
    * Renderer.Console — dep-free, works in IEx/CI (provided)
    * (future) Renderer.HTML / Renderer.LiveView — plug in here.
  """

  @callback render(Tiannara.Interface.ViewModel.t()) :: term()
end
