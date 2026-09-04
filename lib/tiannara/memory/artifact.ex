defmodule Tiannara.Memory.Artifact do
  @moduledoc """
  A single record on the memory ladder with rung, content, evidence, and
  lineage. Lineage makes every promotion traceable
  ("Every architectural decision should remain traceable").
  """

  @enforce_keys [:id, :rung, :content]
  defstruct [:id, :rung, :content, evidence: %{}, lineage: [], confidence: 0.0, created_at: nil]

  def new(rung, content, opts \\ []) do
    %__MODULE__{
      id: gen_id(),
      rung: rung,
      content: content,
      evidence: Keyword.get(opts, :evidence, %{}),
      lineage: Keyword.get(opts, :lineage, []),
      confidence: Keyword.get(opts, :confidence, 0.0),
      created_at: System.system_time(:second)
    }
  end

  defp gen_id, do: "mem-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)
end
