defmodule Tiannara.Foundations.FormalVerification do
  @moduledoc "SMT solving and formal invariant checking."

  def verify_invariants(_model_ast, _invariants) do
    {:error, :formal_verification_unavailable}
  end
end
