defmodule Tiannara.OED.OAVL.ValidationSupervisor do
  @moduledoc """
  📐 OAVL Validation Supervisor.

  Manages child validation and analysis workers inside the Ontological
  Adversarial Validation Layer.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("📐 [OAVL Validation] Booting Ontological Adversarial Validation Layer services...")

    children = [
      Tiannara.OED.OAVL.OntologyValidator,
      Tiannara.OED.OAVL.HiddenAssumptionDetector,
      Tiannara.OED.OAVL.SemanticDriftAnalyzer,
      Tiannara.OED.OAVL.EpistemicCost,
      Tiannara.OED.OAVL.GlobalizationGate
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
