defmodule Tiannara.Archaeology.FossilExcavator do
  @moduledoc """
  Extracts compressed knowledge from deepest EpochalStrata layers.

  ## Current Status: fail-closed.

  This module previously returned hardcoded metric literals (0.99/0.96/0.92)
  regardless of input — classified SIMULATED by the E03 recon harness and
  FALSIFIED at function level (CLAIM-E07). It now fails closed until a real
  fossil-recovery substrate exists. The historical falsification is preserved
  in the certification evidence (MEASUREMENT_INTEGRITY_EVIDENCE.json);
  removing the evidence of fabrication would itself be dishonest.
  """

  @spec excavate(atom(), term()) :: {:error, :archaeology_simulation_unavailable}
  def excavate(_scenario, _payload) do
    {:error, :archaeology_simulation_unavailable}
  end
end

defmodule Tiannara.Archaeology.SemanticReconstructor do
  @moduledoc """
  Pieces together fragmented causal chains broken by timeline merges.

  ## Current Status: fail-closed.

  Previously returned hardcoded metric literals ignoring input (CLAIM-E07
  FALSIFIED). Fails closed until a real semantic-reconstruction substrate exists.
  """

  @spec reconstruct(atom(), term()) :: {:error, :archaeology_simulation_unavailable}
  def reconstruct(_scenario, _payload) do
    {:error, :archaeology_simulation_unavailable}
  end
end

defmodule Tiannara.Archaeology.EpochCompressor do
  @moduledoc """
  Handles extreme compression events transitioning epochs.

  ## Current Status: fail-closed.

  Previously returned hardcoded metric literals ignoring input (CLAIM-E07
  FALSIFIED). Fails closed until a real epoch-compression substrate exists.
  """

  @spec compress(atom(), term()) :: {:error, :archaeology_simulation_unavailable}
  def compress(_scenario, _payload) do
    {:error, :archaeology_simulation_unavailable}
  end
end

defmodule Tiannara.Archaeology.IdentityPreserver do
  @moduledoc """
  Maintains civilizational continuity across radical physical/topological shifts.

  ## Current Status: fail-closed.

  Previously returned a hardcoded 0.99 continuity score ignoring input
  (CLAIM-E07 FALSIFIED). Fails closed until a real identity-continuity
  substrate exists.
  """

  @spec preserve(atom(), term()) :: {:error, :archaeology_simulation_unavailable}
  def preserve(_scenario, _payload) do
    {:error, :archaeology_simulation_unavailable}
  end
end
