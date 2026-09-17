defmodule Tiannara.Omega.HumanAugmentationDeliveryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Omega.HumanAugmentationDelivery
  alias Tiannara.Omega.HumanAugmentationDelivery.{Explanation, Authorization}

  @moduletag :omega_human_augmentation_delivery

  defp sample_package do
    %{
      detected: "monotonic memory growth in cache subsystem",
      investigated: "cache eviction under sustained load",
      hypotheses: ["unbounded cache growth", "missing eviction policy"],
      selected_experiment: %{id: :exp_1, method: :measure_memory_delta},
      generated_candidate: %{id: :cand_1, type: :algorithm_parameter},
      sandbox_result: %{status: :pass},
      certification_confidence: 0.91,
      uncertainty: "eviction cost under extreme load is unmeasured",
      evidence: [100, 110, 120, 130],
      lineage: [:obs_1, :hyp_1, :exp_1, :cand_1]
    }
  end

  test "explain produces an explanation that ALWAYS requires authorization" do
    explanation = HumanAugmentationDelivery.explain(sample_package())
    assert explanation.requires_authorization == true
    assert explanation.detected =~ "memory growth"
    assert explanation.certification_confidence == 0.91
  end

  test "narrative follows the required arc and ends with authorization requirement" do
    explanation = HumanAugmentationDelivery.explain(sample_package())
    narrative = HumanAugmentationDelivery.render(explanation)

    assert narrative =~ "I detected"
    assert narrative =~ "I investigated"
    assert narrative =~ "hypotheses explain it"
    assert narrative =~ "highest expected information gain"
    assert narrative =~ "I generated candidate"
    assert narrative =~ "passed sandbox validation"
    assert narrative =~ "Certification confidence is 0.91"
    assert narrative =~ "Deployment requires human authorization."
  end

  test "narrative states BOTH confidence and uncertainty" do
    explanation = HumanAugmentationDelivery.explain(sample_package())
    narrative = HumanAugmentationDelivery.render(explanation)

    assert narrative =~ "confidence"
    assert narrative =~ "Uncertainty"
  end

  test "authorization cannot be granted without a human_id" do
    explanation = HumanAugmentationDelivery.explain(sample_package())
    {:ok, auth} = HumanAugmentationDelivery.request_authorization(explanation)

    assert {:error, :human_id_required} = Authorization.human_grant(auth, nil)
  end

  test "authorization cannot be granted unless pending" do
    explanation = HumanAugmentationDelivery.explain(sample_package())
    {:ok, prepared} = Authorization.prepare(explanation)

    # Not yet pending — cannot grant.
    assert {:error, {:illegal_transition, _}} = Authorization.human_grant(prepared, :human_1)
  end

  test "a human can grant authorization, producing a valid grant" do
    explanation = HumanAugmentationDelivery.explain(sample_package())
    {:ok, auth} = HumanAugmentationDelivery.request_authorization(explanation)
    {:ok, granted} = Authorization.human_grant(auth, :human_1)

    assert granted.status == :granted
    assert granted.human_id == :human_1
    assert Authorization.valid_for?(granted, explanation.explanation_id)
  end

  test "a denial requires a reason" do
    explanation = HumanAugmentationDelivery.explain(sample_package())
    {:ok, auth} = HumanAugmentationDelivery.request_authorization(explanation)

    assert {:error, :reason_required} = Authorization.human_deny(auth, nil)
    assert {:ok, denied} = Authorization.human_deny(auth, "insufficient evidence")
    assert denied.status == :denied
  end

  test "a grant is only valid for its own explanation" do
    e1 = HumanAugmentationDelivery.explain(sample_package())
    e2 = HumanAugmentationDelivery.explain(Map.put(sample_package(), :detected, "different issue"))

    {:ok, auth1} = HumanAugmentationDelivery.request_authorization(e1)
    {:ok, granted} = Authorization.human_grant(auth1, :human_1)

    assert Authorization.valid_for?(granted, e1.explanation_id)
    refute Authorization.valid_for?(granted, e2.explanation_id)
  end

  test "GenServer delivery → authorization → grant round-trip" do
    {:ok, server} = HumanAugmentationDelivery.start_link(name: nil)

    {:ok, %{explanation: explanation, authorization: auth, narrative: narrative}} =
      HumanAugmentationDelivery.deliver(server, sample_package())

    assert narrative =~ "Deployment requires human authorization."
    assert [auth_id] = HumanAugmentationDelivery.pending(server)
    assert auth_id == auth.authorization_id

    {:ok, granted} = HumanAugmentationDelivery.authorize(server, auth.authorization_id, :human_1)
    assert granted.status == :granted
    assert HumanAugmentationDelivery.pending(server) == []

    GenServer.stop(server)
  end

  test "there is no autonomous path to a valid grant" do
    explanation = HumanAugmentationDelivery.explain(sample_package())

    # Every path to a grant requires a human_id at the pending stage.
    {:ok, auth} = HumanAugmentationDelivery.request_authorization(explanation)

    # Cannot grant from :prepared.
    {:ok, prepared} = Authorization.prepare(explanation)
    assert {:error, _} = Authorization.human_grant(prepared, :human_1)

    # Cannot grant from :pending without human_id.
    assert {:error, :human_id_required} = Authorization.human_grant(auth, nil)

    # Only a real human_id at :pending produces a grant.
    assert {:ok, %{status: :granted}} = Authorization.human_grant(auth, :human_1)
  end
end
defmodule Tiannara.Omega.HumanDeliveryTest do
  use ExUnit.Case, async: false

  alias Tiannara.Omega.HumanDelivery
  alias Tiannara.Omega.HumanDelivery.{Explanation, Authorization}

  @moduletag :omega_human_delivery

  defp sample_package do
    %{
      detected: "monotonic memory growth in cache subsystem",
      investigated: "cache eviction under sustained load",
      hypotheses: ["unbounded cache growth", "missing eviction policy"],
      selected_experiment: %{id: :exp_1, method: :measure_memory_delta},
      generated_candidate: %{id: :cand_1, type: :algorithm_parameter},
      sandbox_result: %{status: :pass},
      certification_confidence: 0.91,
      uncertainty: "eviction cost under extreme load is unmeasured",
      evidence: [100, 110, 120, 130],
      lineage: [:obs_1, :hyp_1, :exp_1, :cand_1]
    }
  end

  test "explain produces an explanation that ALWAYS requires authorization" do
    explanation = HumanDelivery.explain(sample_package())
    assert explanation.requires_authorization == true
    assert explanation.detected =~ "memory growth"
    assert explanation.certification_confidence == 0.91
  end

  test "narrative follows the required arc and ends with authorization requirement" do
    explanation = HumanDelivery.explain(sample_package())
    narrative = HumanDelivery.render(explanation)

    assert narrative =~ "I detected"
    assert narrative =~ "I investigated"
    assert narrative =~ "hypotheses explain it"
    assert narrative =~ "highest expected information gain"
    assert narrative =~ "I generated candidate"
    assert narrative =~ "passed sandbox validation"
    assert narrative =~ "Certification confidence is 0.91"
    assert narrative =~ "Deployment requires human authorization."
  end

  test "narrative states BOTH confidence and uncertainty" do
    explanation = HumanDelivery.explain(sample_package())
    narrative = HumanDelivery.render(explanation)

    assert narrative =~ "confidence"
    assert narrative =~ "Uncertainty"
  end

  test "authorization cannot be granted without a human_id" do
    explanation = HumanDelivery.explain(sample_package())
    {:ok, auth} = HumanDelivery.request_authorization(explanation)

    assert {:error, :human_id_required} = Authorization.human_grant(auth, nil)
  end

  test "authorization cannot be granted unless pending" do
    explanation = HumanDelivery.explain(sample_package())
    {:ok, prepared} = Authorization.prepare(explanation)

    # Not yet pending — cannot grant.
    assert {:error, {:illegal_transition, _}} = Authorization.human_grant(prepared, :human_1)
  end

  test "a human can grant authorization, producing a valid grant" do
    explanation = HumanDelivery.explain(sample_package())
    {:ok, auth} = HumanDelivery.request_authorization(explanation)
    {:ok, granted} = Authorization.human_grant(auth, :human_1)

    assert granted.status == :granted
    assert granted.human_id == :human_1
    assert Authorization.valid_for?(granted, explanation.explanation_id)
  end

  test "a denial requires a reason" do
    explanation = HumanDelivery.explain(sample_package())
    {:ok, auth} = HumanDelivery.request_authorization(explanation)

    assert {:error, :reason_required} = Authorization.human_deny(auth, nil)
    assert {:ok, denied} = Authorization.human_deny(auth, "insufficient evidence")
    assert denied.status == :denied
  end

  test "a grant is only valid for its own explanation" do
    e1 = HumanDelivery.explain(sample_package())
    e2 = HumanDelivery.explain(Map.put(sample_package(), :detected, "different issue"))

    {:ok, auth1} = HumanDelivery.request_authorization(e1)
    {:ok, granted} = Authorization.human_grant(auth1, :human_1)

    assert Authorization.valid_for?(granted, e1.explanation_id)
    refute Authorization.valid_for?(granted, e2.explanation_id)
  end

  test "GenServer delivery → authorization → grant round-trip" do
    {:ok, server} = HumanDelivery.start_link(name: nil)

    {:ok, %{explanation: explanation, authorization: auth, narrative: narrative}} =
      HumanDelivery.deliver(server, sample_package())

    assert narrative =~ "Deployment requires human authorization."
    assert [auth_id] = HumanDelivery.pending(server)
    assert auth_id == auth.authorization_id

    {:ok, granted} = HumanDelivery.authorize(server, auth.authorization_id, :human_1)
    assert granted.status == :granted
    assert HumanDelivery.pending(server) == []

    GenServer.stop(server)
  end

  test "there is no autonomous path to a valid grant" do
    explanation = HumanDelivery.explain(sample_package())

    # Every path to a grant requires a human_id at the pending stage.
    {:ok, auth} = HumanDelivery.request_authorization(explanation)

    # Cannot grant from :prepared.
    {:ok, prepared} = Authorization.prepare(explanation)
    assert {:error, _} = Authorization.human_grant(prepared, :human_1)

    # Cannot grant from :pending without human_id.
    assert {:error, :human_id_required} = Authorization.human_grant(auth, nil)

    # Only a real human_id at :pending produces a grant.
    assert {:ok, %{status: :granted}} = Authorization.human_grant(auth, :human_1)
  end
end