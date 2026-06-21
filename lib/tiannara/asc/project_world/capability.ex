defmodule Tiannara.ASC.ProjectWorld.Capability do
  @moduledoc """
  A user-facing capability extracted from project requirements.

  Capabilities are the actions the system must be able to perform.
  Each capability becomes the target for unit and integration test contracts.

  ## Examples

      "create account"
      "transfer funds between accounts"
      "generate monthly statement"

  ## Lifecycle

  Requirements.Extractor → ProjectWorld.capabilities →
  Testing.Civilization (→ :unit + :integration TestContracts) →
  Implementation.Civilization (→ function stub per capability)
  """

  @derive Jason.Encoder

  defstruct [
    :id,
    :name,
    :description,
    :verb,             # primary action verb ("create", "transfer", "generate")
    :subject,          # entity being acted upon ("account", "funds", "statement")
    :actor,            # who performs it
    :inputs,
    :outputs,
    :preconditions,
    :postconditions,
    tags: []
  ]

  @type actor :: :user | :system | :external | :unknown

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    description: String.t() | nil,
    verb: String.t(),
    subject: String.t(),
    actor: actor(),
    inputs: [String.t()],
    outputs: [String.t()],
    preconditions: [String.t()],
    postconditions: [String.t()],
    tags: [String.t()]
  }

  @spec new(String.t(), keyword()) :: t()
  def new(name, opts \\ []) do
    {verb, subject} = parse_name(name)

    %__MODULE__{
      id: "cap_#{:erlang.unique_integer([:positive, :monotonic])}",
      name: name,
      description: Keyword.get(opts, :description),
      verb: verb,
      subject: subject,
      actor: Keyword.get(opts, :actor, :unknown),
      inputs: Keyword.get(opts, :inputs, []),
      outputs: Keyword.get(opts, :outputs, []),
      preconditions: Keyword.get(opts, :preconditions, []),
      postconditions: Keyword.get(opts, :postconditions, []),
      tags: Keyword.get(opts, :tags, [])
    }
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp parse_name(name) do
    case String.split(name, " ", parts: 2) do
      [v, s] -> {String.downcase(v), s}
      [v]    -> {String.downcase(v), "entity"}
    end
  end
end
