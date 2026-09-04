defmodule Tiannara.Executive.Auditor do
  @moduledoc """
  Constitutional validation for every write to Executive Memory.

  Enforces:
  - Memory class validity
  - Lineage presence for non-operational classes
  - Immutability of archaeological and constitutional records
  - Minimum evidence threshold
  """

  require Logger

  alias Tiannara.Executive.Types

  @doc "Audits a write operation. Returns :ok or {:error, reason}."
  def audit(key, attrs \\ %{}) do
    class = Map.get(attrs, :class, :operational)
    lineage = Map.get(attrs, :lineage)

    with :ok <- validate_class(class),
         :ok <- validate_lineage_presence(class, lineage),
         :ok <- validate_immutability(key, class),
         :ok <- validate_evidence(lineage) do
      :ok
    end
  end

  @doc "Audits a write against existing state (for updates)."
  def audit_write(key, new_attrs, existing_state) do
    existing_class = Map.get(existing_state, :class, :operational)

    if existing_class in [:archaeological, :constitutional] do
      {:error, :immutable_record}
    else
      audit(key, new_attrs)
    end
  end

  defp validate_class(class) do
    if Types.valid_class?(class), do: :ok, else: {:error, :invalid_class}
  end

  defp validate_lineage_presence(class, lineage) when class in [:archaeological, :constitutional, :scientific] do
    if lineage && Tiannara.Executive.Lineage.valid?(lineage) do
      :ok
    else
      {:error, {:missing_or_invalid_lineage, class}}
    end
  end

  defp validate_lineage_presence(_class, _lineage), do: :ok

  defp validate_immutability(_key, class) when class in [:archaeological, :constitutional], do: {:error, :immutable_class}
  defp validate_immutability(_key, _class), do: :ok

  defp validate_evidence(nil), do: :ok
  defp validate_evidence(%Tiannara.Executive.Lineage{evidence_level: level}) when level >= 0.1, do: :ok
  defp validate_evidence(%{confidence_score: score}) when is_number(score) and score >= 0.1, do: :ok
  defp validate_evidence(_), do: {:error, :below_evidence_threshold}
end
