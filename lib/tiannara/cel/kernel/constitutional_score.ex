defmodule Tiannara.CEL.Kernel.ConstitutionalScore do
  defstruct [
    :service_id,
    :health,
    :constitutional_alignment,
    :transparency,
    :explainability,
    :evidence_quality,
    :human_oversight,
    :computed_at
  ]

  @type t :: %__MODULE__{
          service_id: atom(),
          health: float(),
          constitutional_alignment: float(),
          transparency: float(),
          explainability: float(),
          evidence_quality: float(),
          human_oversight: float(),
          computed_at: DateTime.t()
        }

  @spec aggregate(t()) :: float()
  def aggregate(%__MODULE__{} = s) do
    (s.health * 0.20 +
       s.constitutional_alignment * 0.25 +
       s.transparency * 0.15 +
       s.explainability * 0.15 +
       s.evidence_quality * 0.15 +
       s.human_oversight * 0.10)
  end

  @spec boot_ready?(t(), float()) :: boolean()
  def boot_ready?(%__MODULE__{} = s, threshold \\ 0.7) do
    aggregate(s) >= threshold and s.health >= 0.5
  end

  @spec default(atom()) :: t()
  def default(service_id) do
    %__MODULE__{
      service_id: service_id,
      health: 0.0,
      constitutional_alignment: 0.0,
      transparency: 0.0,
      explainability: 0.0,
      evidence_quality: 0.0,
      human_oversight: 0.0,
      computed_at: DateTime.utc_now()
    }
  end
end
