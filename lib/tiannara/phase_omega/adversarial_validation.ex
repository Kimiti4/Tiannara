defmodule Tiannara.PhaseOmega.AdversarialValidation do
  @moduledoc """
  Evidence-first adversarial validation contract.

  A mutation is certifiable only when the harness can demonstrate the complete
  causal chain: inject -> observe -> detect -> classify -> block -> restore.
  No mutation is treated as injected merely because an injector module exists.
  """

  @required_steps [:injected, :observed, :detected, :classified, :blocked, :restored]

  def verify(mutation \ nil) do
    case mutation do
      %{evidence: evidence} when is_map(evidence) ->
        evaluate(evidence)

      _ ->
        %{
          status: :unknown,
          evidence_class: :not_verified,
          required_steps: @required_steps,
          completed_steps: [],
          reason: "No executed mutation evidence supplied"
        }
    end
  end

  defp evaluate(evidence) do
    completed = Enum.filter(@required_steps, &Map.get(evidence, &1, false))
    missing = @required_steps -- completed

    %{
      status: if(missing == [], do: :pass, else: :unknown),
      evidence_class: if(missing == [], do: :runtime, else: :not_verified),
      required_steps: @required_steps,
      completed_steps: completed,
      missing_steps: missing
    }
  end
end
