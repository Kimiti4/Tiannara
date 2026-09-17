defmodule Tiannara.Phase14.Formal.EquivocationDetector do
  @moduledoc "Detects conflicting votes from the same instance in a single round"
  
  @spec detect(round :: map(), voter :: String.t(), phase :: atom(), hash :: String.t()) :: boolean()
  def detect(round, voter, phase, hash) do
    votes = Map.get(round, :"#{phase}_votes", %{})
    Map.has_key?(votes, voter) and Map.get(votes, voter) != hash
  end
end