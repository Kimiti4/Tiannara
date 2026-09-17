defmodule Rbac.Policy do
  @moduledoc """
  Constitutional Policy Engine.

  Policies declare: who can do what, under what conditions, with justification.

  Policy structure:
    id — name — rule — justification — evidence — constraints — audit_level
  """

  defstruct [:id, :name, :rule, :justification, :evidence, :constraints, :audit_level]

  @type constraint :: %{field: atom(), operator: :eq | :neq | :in | :gt | :lt, value: term()}

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          rule: (map() -> boolean()),
          justification: String.t(),
          evidence: String.t(),
          constraints: [constraint],
          audit_level: :none | :info | :audit | :critical
        }

  def new(name, opts \\ []) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      name: name,
      rule: opts[:rule] || default_rule(),
      justification: opts[:justification] || "Constitutional default",
      evidence: opts[:evidence] || "Self-evident",
      constraints: opts[:constraints] || [],
      audit_level: opts[:audit_level] || :audit
    }
  end

  def evaluate(%__MODULE__{rule: rule, constraints: constraints} = policy, context) do
    constraints_met = Enum.all?(constraints, fn c -> check_constraint(c, context) end)
    rule_result = rule.(context)

    if constraints_met and rule_result do
      {:granted, policy}
    else
      {:denied, policy, reason(context, constraints, rule_result)}
    end
  end

  defp check_constraint(%{field: f, operator: :eq, value: v}, ctx),
    do: Map.get(ctx, f) == v

  defp check_constraint(%{field: f, operator: :neq, value: v}, ctx),
    do: Map.get(ctx, f) != v

  defp check_constraint(%{field: f, operator: :in, value: v}, ctx),
    do: Map.get(ctx, f) in v

  defp check_constraint(%{field: f, operator: :gt, value: v}, ctx),
    do: Map.get(ctx, f) > v

  defp check_constraint(%{field: f, operator: :lt, value: v}, ctx),
    do: Map.get(ctx, f) < v

  defp default_rule, do: fn _context -> true end

  defp reason(_ctx, constraints, rule_result) do
    cond do
      not rule_result -> "Rule evaluated to false"
      length(constraints) > 0 -> "Constraint not met"
      true -> "Unknown"
    end
  end

  def constitutional do
    %{
      certification_sign:
        new("certification_sign",
          justification: "Only Certification Auditor can sign constitutional certificates.",
          constraints: [%{field: :role, operator: :eq, value: :auditor}],
          rule: fn ctx -> ctx[:capability] == "certification.sign" end
        ),
      runtime_shutdown:
        new("runtime_shutdown",
          justification: "Only Administrator can shut down runtime.",
          constraints: [%{field: :role, operator: :in, value: [:administrator, :governor]}],
          rule: fn ctx -> ctx[:capability] == "runtime.shutdown" end
        ),
      audit_read:
        new("audit_read",
          justification: "Only Auditor and Governor can read audit trails.",
          constraints: [
            %{field: :role, operator: :in, value: [:auditor, :governor, :administrator]}
          ],
          rule: fn ctx -> String.starts_with?(ctx[:capability], "audit.") end
        )
    }
  end
end
