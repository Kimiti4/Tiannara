defmodule Tiannara.EHTC do
  @moduledoc """
  Public compute facade for the Event Horizon Tensor Core fabric.

  EHTC is a runtime abstraction, not literal black-hole computation. The
  production contract is bounded tensor execution with queueing, backpressure,
  provenance and a replaceable backend (Nx CPU today; accelerator backends may
  be added later).
  """

  @type compute_result :: %{
          backend: atom(),
          core_id: atom(),
          operation: atom(),
          duration_us: non_neg_integer(),
          metadata: map()
        }

  @spec compute_principal_eigenvectors(Nx.Tensor.t(), pos_integer(), keyword()) ::
          {:ok, Nx.Tensor.t(), map()} | {:error, term()}
  def compute_principal_eigenvectors(tensor, components, opts \\ []) do
    Tiannara.Meta.Hardware.HorizonScheduler.compute_principal_eigenvectors(
      tensor,
      components,
      opts
    )
  end

  @spec execute(atom(), term(), keyword()) :: {:ok, term(), compute_result()} | {:error, term()}
  def execute(operation, payload, opts \\ []) do
    Tiannara.Meta.Hardware.HorizonScheduler.execute(operation, payload, opts)
  end
end
