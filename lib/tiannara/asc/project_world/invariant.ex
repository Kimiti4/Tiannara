defmodule Tiannara.ASC.ProjectWorld.Invariant do
  @moduledoc """
  A formal invariant extracted from project requirements.

  Invariants are constraints that must **always** hold — they become
  the primary targets for property-based testing (StreamData/QuickCheck)
  and formal verification in the Crucible phase.

  ## Examples

      "user_id must be unique"
      "account balance cannot go below zero"
      "order total must equal the sum of line items"

  ## Lifecycle

  Requirements.Extractor → ProjectWorld.invariants →
  Testing.Civilization (→ :property TestContract) →
  Crucible.Attacker (adversarial violation attempts)
  """

  @derive Jason.Encoder

  defstruct [
    :id,
    :statement,
    :domain,          # :data_integrity | :security | :performance | :business_logic | :general
    :strength,        # :must | :should | :may
    :source_fragment, # original text fragment from the project goal
    :negation_form,   # violation description e.g. "balance < 0 is INVALID"
    tags: []
  ]

  @type domain :: :data_integrity | :security | :performance | :business_logic | :general
  @type strength :: :must | :should | :may

  @type t :: %__MODULE__{
    id: String.t(),
    statement: String.t(),
    domain: domain(),
    strength: strength(),
    source_fragment: String.t(),
    negation_form: String.t() | nil,
    tags: [String.t()]
  }

  @spec new(String.t(), keyword()) :: t()
  def new(statement, opts \\ []) do
    %__MODULE__{
      id: "inv_#{:erlang.unique_integer([:positive, :monotonic])}",
      statement: statement,
      domain: Keyword.get(opts, :domain, :general),
      strength: Keyword.get(opts, :strength, :must),
      source_fragment: Keyword.get(opts, :source_fragment, statement),
      negation_form: Keyword.get(opts, :negation_form),
      tags: Keyword.get(opts, :tags, [])
    }
  end
end
