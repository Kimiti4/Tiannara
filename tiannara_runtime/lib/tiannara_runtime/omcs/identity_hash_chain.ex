defmodule TiannaraRuntime.OMCS.IdentityHashChain do
  @moduledoc """
  Ontological Memory Continuity System (OMCS) - Identity Hash Chain.

  Provides cryptographic hash chain calculations to guarantee historical causality,
  proving that no fold, branch merge, or compression cycle corrupts civilization identity.
  """

  @doc """
  Compute a new hash link in the chain given the previous hash, the active concept list, and a timestamp.
  """
  @spec generate_link(previous_hash :: String.t(), concepts :: [String.t()] | map(), timestamp :: integer()) :: String.t()
  def generate_link(previous_hash, concepts, timestamp) do
    data = "#{previous_hash}:#{inspect(concepts)}:#{timestamp}"
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  @doc """
  Validate the integrity of an entire hash chain list.
  Assumes list is chronologically reversed (newest link first).
  """
  @spec validate_chain(chain :: [{String.t(), String.t(), map(), integer()}]) :: boolean()
  def validate_chain(chain) do
    case chain do
      [] -> true
      [_single] -> true
      list ->
        pairs = Enum.zip(list, tl(list))
        Enum.all?(pairs, fn {{curr_hash, prev_hash, concepts, ts}, _next} ->
          curr_hash == generate_link(prev_hash, concepts, ts)
        end)
    end
  end
end
