defmodule Tiannara.TWP.TimelineRegistry do
  @moduledoc """
  OTP Supervisor tracking all active, compressed, and archived branches.
  """
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  def init(_opts) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
  
  def register_timeline(_id, _state), do: :ok
end
