defmodule Tiannara.EpistemicMirror.MirrorRegistry do
  @moduledoc """
  OTP Supervisor for the active Epistemic Mirror self-models.
  """
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  def init(_opts) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
