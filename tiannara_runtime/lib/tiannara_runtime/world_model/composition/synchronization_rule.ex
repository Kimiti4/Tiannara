defmodule TiannaraRuntime.WorldModel.Composition.SynchronizationRule do
  @moduledoc """
  Phase 17.6.1 — SynchronizationRule struct.
  A deterministic rule specifying how two models exchange state.
  Fields: rule_id, source_model, target_model, variable, mode, frequency, transform, metadata.
  """
  defstruct [
    :rule_id, :source_model, :target_model, :variable,
    :mode, :frequency, :transform, :metadata
  ]

  @type mode :: :discrete | :continuous | :event_driven
  @type t :: %__MODULE__{
          rule_id: String.t() | nil,
          source_model: String.t() | nil,
          target_model: String.t() | nil,
          variable: String.t() | nil,
          mode: mode() | nil,
          frequency: non_neg_integer() | nil,
          transform: map() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "sr_" <> hash
  end
end
