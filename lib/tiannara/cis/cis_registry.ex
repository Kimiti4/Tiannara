defmodule Tiannara.CIS.CISRegistry do
  @moduledoc """
  OTP Supervisor tracking active immune responses.
  """
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  def init(_opts) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
