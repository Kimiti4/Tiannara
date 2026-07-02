defmodule Tiannara.OCM.OntologyRegistry do
  @moduledoc """
  OTP Supervisor tracking all registered ontology schemas across the Multiverse.
  """
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  def init(_opts) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end