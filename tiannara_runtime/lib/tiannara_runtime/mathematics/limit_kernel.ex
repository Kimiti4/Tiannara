defmodule TiannaraRuntime.Mathematics.LimitKernel do
  @moduledoc """
  Explicit sequence/limit proof substrate.

  A limit claim is represented with its domain, target and evidence. This
  kernel currently establishes only exact constant/equal-to-target sequences
  and explicit limit evidence supplied by a verified backend. Finite samples
  alone never establish convergence or a limit.
  """

  def define(sequence, variable, target, domain) do
    {:ok, %{sequence: sequence, variable: variable, target: target,
            domain: domain, status: :defined, certification_eligible: false}}
  end

  def prove(%{sequence: {:constant, target}, target: target} = claim),
      do: {:ok, :proved, %{rule: :constant_sequence, claim: claim}}

  def prove(%{evidence: %{status: :proved, verifier_id: verifier}} = claim)
      when is_binary(verifier),
      do: {:ok, :proved, %{rule: :verified_limit_backend, claim: claim}}

  def prove(%{evidence: _}), do: {:ok, :not_established, %{rule: :limit_evidence_insufficient}}
  def prove(_), do: {:ok, :not_established, %{rule: :limit_backend_required}}
end
