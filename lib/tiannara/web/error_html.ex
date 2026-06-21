defmodule TiannaraWeb.ErrorHTML do
  @moduledoc """
  Error HTML rendering.
  """
  use Phoenix.Component

  def render(template, _assigns) do
    "Error: #{template}"
  end
end
