defmodule Tiannara.CRAV.AlphaLaunchAuthorizationTest do
  use ExUnit.Case, async: true

  alias Tiannara.CRAV.AlphaLaunch

  test "launch without an authorization grant is rejected before activation" do
    assert {:error, :authorization_required} = AlphaLaunch.launch()
  end

  test "wrong consequential action id is rejected" do
    assert {:error, :invalid_alpha_launch_authorization} =
             AlphaLaunch.launch(:other_action, :grant, :identity, "/tmp/registry.jsonl")
  end
end
