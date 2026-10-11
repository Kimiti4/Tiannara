defmodule Tiannara.AEOTest do
  use ExUnit.Case, async: false

  defmodule RuntimeAdapter do
    def submit(%{id: id}) do
      {:ok, %{execution_id: "runtime-" <> id, status: :accepted}}
    end
  end

  defmodule InvalidRuntimeAdapter do
    def submit(_graph), do: {:ok, :submitted}
  end

  setup do
    previous = Application.get_env(:tiannara, :aeo_runtime_adapter)
    Application.delete_env(:tiannara, :aeo_runtime_adapter)

    on_exit(fn ->
      if is_nil(previous) do
        Application.delete_env(:tiannara, :aeo_runtime_adapter)
      else
        Application.put_env(:tiannara, :aeo_runtime_adapter, previous)
      end
    end)

    :ok
  end

  test "translates equivalent intent into a stable, inspectable graph" do
    assert {:ok, first} = Tiannara.AEO.translate_intent(%{id: "goal-1", description: "  review logs ", priority: :high})
    assert {:ok, second} = Tiannara.AEO.translate_intent(%{id: "goal-1", description: "review logs", priority: :high})

    assert first.id == second.id
    assert first.nodes == second.nodes
    assert first.status == :planned
    assert [%{operation: :evaluate_goal, requires_runtime_authorization: true}] = first.nodes
  end

  test "rejects empty or malformed intent" do
    assert {:error, :empty_intent} = Tiannara.AEO.translate_intent("  ")
    assert {:error, :missing_description} = Tiannara.AEO.translate_intent(%{id: "no-description"})
    assert {:error, :invalid_intent} = Tiannara.AEO.translate_intent(nil)
  end

  test "does not claim runtime submission when no adapter is configured" do
    assert {:ok, graph} = Tiannara.AEO.translate_intent("inspect service health")
    assert {:error, :runtime_unavailable} = Tiannara.AEO.submit_to_runtime(graph)
  end

  test "accepts only a structured runtime receipt" do
    Application.put_env(:tiannara, :aeo_runtime_adapter, RuntimeAdapter)
    assert {:ok, graph} = Tiannara.AEO.translate_intent("inspect service health")
    assert {:ok, %{status: :accepted, receipt: %{execution_id: _, status: :accepted}}} =
             Tiannara.AEO.submit_to_runtime(graph)

    Application.put_env(:tiannara, :aeo_runtime_adapter, InvalidRuntimeAdapter)
    assert {:error, :invalid_runtime_receipt} = Tiannara.AEO.submit_to_runtime(graph)
  end

  test "rejects invalid domain weights" do
    assert {:ok, [:primary, :secondary]} =
             Tiannara.AEO.assemble_domain_team(:goal, %{secondary: 0.2, primary: 0.9})

    assert {:error, :invalid_domain_weights} =
             Tiannara.AEO.assemble_domain_team(:goal, %{primary: :unknown})
  end
end
