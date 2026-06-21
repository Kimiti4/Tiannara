defmodule TiannaraOS.HumanCollaborator do
  @moduledoc """
  Represents human/external validation actors participating in the truth loop.
  """

  @derive Jason.Encoder
  defstruct [
    :id,            # atom() - unique identifier
    expertise: [],  # list(atom()) - domains of expertise
    trust_score: 1.0, # float() - normalized weight of validation (0.0 to 1.0)
    role: :reviewer,  # atom() - :reviewer, :auditor, :approver, :domain_expert, :security_reviewer
    organization: nil, # string() | nil - optional validating organization
    last_active_at: nil # DateTime.t() | nil - timestamp of last review
  ]

  @type t :: %__MODULE__{
    id: atom(),
    expertise: [atom()],
    trust_score: float(),
    role: :reviewer | :auditor | :approver | :domain_expert | :security_reviewer,
    organization: String.t() | nil,
    last_active_at: DateTime.t() | nil
  }
end
