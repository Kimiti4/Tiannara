defmodule TiannaraWeb.ErrorJSON do
  @moduledoc """
  Error JSON rendering.
  """
  def render(template, _assigns) do
    %{error: to_string(template)}
  end
end
