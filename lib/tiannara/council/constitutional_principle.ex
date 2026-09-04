defmodule Tiannara.Council.ConstitutionalPrinciple do
  @moduledoc """
  Behaviour for constitutional principle plugins.

  Every principle must implement this behaviour, enabling independent
  versioning, testing, dynamic registration, and audit traceability.

  Constitutional Alignment:
    - Modularity: Principles are discrete, replaceable units.
    - Independent replacement: New principles added without touching core engine.
    - Traceability: Every evaluation tagged with principle version and identity.
  """

  @type principle_id :: atom()
  @type verdict :: :strengthened | :neutral | :violated

  @type evaluation_result :: %{
          principle_id: principle_id(),
          principle_name: String.t(),
          version: String.t(),
          verdict: verdict(),
          reasoning: String.t(),
          evidence: [map()],
          weight: float()
        }

  @callback id() :: principle_id()
  @callback name() :: String.t()
  @callback version() :: String.t()
  @callback weight() :: float()
  @callback evaluate(atom(), map(), map() | nil) :: evaluation_result()
end
