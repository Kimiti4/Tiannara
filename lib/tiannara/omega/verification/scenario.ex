defmodule Tiannara.Omega.Verification.Scenario do
  @moduledoc """
  Behaviour for a verification scenario. Each scenario performs an attack
  against the Ω.R pipeline interfaces and returns structured evidence.

  Constitutional basis: Verification First ("Adversarial testing"),
  "Capability must never outpace verification."
  """

  alias Tiannara.Omega.Verification.{World, Baseline, ScenarioOutcome}

  @callback name() :: atom()
  @callback attack_type() :: atom()
  @callback invariant() :: atom()
  @callback boundary() :: atom()
  @callback attack(World.t(), Baseline.t()) :: ScenarioOutcome.t()
end