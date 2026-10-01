defmodule TiannaraRuntime.Research.CrossDomainImprovementTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Research.CrossDomainImprovement

  test "certified discoveries from multiple domains can form one proposal" do
    discoveries = [
      %{domain: "cybernetics", certification_status: :certified, evidence: %{acl: :pass}},
      %{domain: "computation", certification_status: :certified, evidence: %{oavl: :pass}},
      %{domain: "physics", certification_status: :candidate, evidence: %{tests: 20}}
    ]

    {:ok, result} = CrossDomainImprovement.propose(discoveries, :runtime)
    assert length(result.discoveries) == 2
    assert result.implementation_allowed == false
  end

  test "uncertified discoveries cannot enter the certified improvement evidence set" do
    {:ok, result} =
      CrossDomainImprovement.propose([
        %{domain: "cybernetics", certification_status: :candidate, evidence: %{}}
      ], :runtime)

    assert result.status == :no_certified_discovery
  end
end
