defmodule Tiannara.Stabilization.OCM.ConflictResolver do
  @moduledoc false

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
end
