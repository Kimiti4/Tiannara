defmodule Tiannara.ASC.Civilization.LLMProvider do
  @moduledoc """
  Phase 9: The interface for agentic reasoning. 
  Implementations can range from Heuristic simulations to real API calls.
  """
  @callback generate_design(String.t(), map()) :: map()
  @callback generate_patch(map(), map(), String.t() | nil) :: list()
  @callback review_patch(map(), list(), map()) :: {:approved, String.t()} | {:rejected, String.t()}
end
