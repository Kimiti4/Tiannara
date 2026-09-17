defmodule ObservatoryCore.Types.Layout do
  defstruct [:dashboard_id, :version, :title, :widgets, :layout, :created_at, :updated_at]

  @type t :: %__MODULE__{
          dashboard_id: String.t(),
          version: String.t(),
          title: String.t(),
          widgets: [ObservatoryCore.Types.Widget.t()],
          layout: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  def new(attrs \\ %{}) do
    struct!(__MODULE__, attrs)
  end
end
