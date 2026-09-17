defmodule TiannaraRuntimeWeb.ErrorView do
  def render("404.json", _assigns) do
    %{error: "not found"}
  end

  def render("500.json", _assigns) do
    %{error: "internal server error"}
  end

  def render(template, _assigns) do
    %{error: Phoenix.Controller.status_message_from_template(template)}
  end
end
