defmodule Tiannara.Discovery.Validation.Domain do
  defmodule ValidationReport do
    defstruct [:id, :discovery_id, :statistical_validation, :replication_status,
      :reproducibility_score, :evidence_audit, :calibration_result, :certification,
      :overall_score, :recommendation, :validated_at]

    @type t :: %__MODULE__{}
    @certifications [:certified, :provisional, :uncertified, :rejected]
    def certifications, do: @certifications

    def new(attrs) do
      %__MODULE__{
        id: "val_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        validated_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule StatisticalValidation do
    defstruct [:significance_level, :p_value, :effect_size, :statistical_power,
      :confidence_interval, :sample_size, :sufficient_power, :significant, :details]

    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{significance_level: 0.05, sufficient_power: false, significant: false, details: []} |> struct(attrs)
    end
  end

  defmodule ReplicationPlan do
    defstruct [:id, :discovery_id, :original_experiment_ids, :replication_experiments,
      :independence_criteria, :success_criteria, :status, :created_at]

    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{
        id: "repl_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        replication_experiments: [], independence_criteria: [], success_criteria: [],
        status: :planned, created_at: DateTime.utc_now()
      } |> struct(attrs)
    end
  end

  defmodule Certification do
    defstruct [:discovery_id, :level, :confidence, :uncertainty, :evidence_count,
      :replication_count, :validation_score, :certified_at, :expires_at, :conditions]

    @type t :: %__MODULE__{}
    def new(attrs) do
      %__MODULE__{conditions: [], certified_at: DateTime.utc_now()} |> struct(attrs)
    end
  end
end
