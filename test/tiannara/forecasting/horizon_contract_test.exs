defmodule Tiannara.Forecasting.HorizonContractTest do
  @moduledoc """
  Verification of the typed forecast horizon (TCP-B-059) and of the canonical
  scoring implementation (TCP-002.5 Stage 9).

  ## The scoring convention

  `Tiannara.Forecasting.Calibration.score/2` uses the **binary convention**:
  the realised outcome is encoded as `y = 1`, and `p` is the probability the
  forecast assigned to that realised outcome. Under that convention

      Brier    = (p - 1)^2
      LogLoss  = -ln(p)

  The vectors below are calculated independently of the implementation, from
  the formula above, so the test is a known-answer test rather than a
  self-consistency check. Boundary probabilities (p = 0 or p = 1) are
  `:unknown` for log loss — the implementation's documented convention — and
  are asserted as such rather than assumed.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Calibration, Contracts, Forecast}
  alias Tiannara.Forecasting.Contracts.Horizon

  defp dt(iso) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(iso)
    datetime
  end

  defp horizon(start_iso, end_iso, policy \\ :closed) do
    {:ok, h} =
      Horizon.from_iso(%{
        start_at: start_iso,
        end_at: end_iso,
        policy: policy
      })

    h
  end

  defp forecast(probabilities, outcomes \\ ["yes", "no"]) do
    Forecast.new(
      question: "Will it converge?",
      outcomes: outcomes,
      probabilities: probabilities,
      horizon: "24h",
      typed_horizon: horizon("2026-06-01T00:00:00Z", "2026-06-02T00:00:00Z")
    )
  end

  describe "typed horizon construction" do
    test "a valid horizon is built and normalised to UTC" do
      h = horizon("2026-06-01T02:00:00+02:00", "2026-06-02T00:00:00Z")

      assert h.start_at == dt("2026-06-01T00:00:00Z")
      assert h.end_at == dt("2026-06-02T00:00:00Z")
      assert h.policy == :closed
      assert h.version == 1
    end

    test "a missing start is refused with an exact reason" do
      assert {:error, :missing_horizon_start_at} =
               Horizon.from_iso(%{start_at: nil, end_at: "2026-06-02T00:00:00Z"})
    end

    test "a missing end is refused with an exact reason" do
      assert {:error, :missing_horizon_end_at} =
               Horizon.from_iso(%{start_at: "2026-06-01T00:00:00Z", end_at: nil})
    end

    test "an end before the start is refused" do
      assert {:error, :horizon_end_before_start} =
               Horizon.from_iso(%{
                 start_at: "2026-06-02T00:00:00Z",
                 end_at: "2026-06-01T00:00:00Z"
               })
    end

    test "an unparseable timestamp is refused" do
      assert {:error, :invalid_horizon_timestamp} =
               Horizon.from_iso(%{
                 start_at: "not a time",
                 end_at: "2026-06-02T00:00:00Z"
               })
    end

    test "an unrecognised policy is refused" do
      assert {:error, :invalid_horizon_policy} =
               Horizon.from_iso(%{
                 start_at: "2026-06-01T00:00:00Z",
                 end_at: "2026-06-02T00:00:00Z",
                 policy: "whenever"
               })
    end
  end

  describe "temporal eligibility" do
    test "an event inside the target period is eligible" do
      h = horizon("2026-06-01T00:00:00Z", "2026-06-02T00:00:00Z")

      assert Horizon.event_within?(h, dt("2026-06-01T12:00:00Z"))
    end

    test "an event outside the target period is not eligible" do
      h = horizon("2026-06-01T00:00:00Z", "2026-06-02T00:00:00Z")

      refute Horizon.event_within?(h, dt("2026-05-31T23:59:59Z"))
      refute Horizon.event_within?(h, dt("2026-06-02T00:00:01Z"))
    end

    test "a closed policy refuses evidence published after the deadline" do
      h = horizon("2026-06-01T00:00:00Z", "2026-06-02T00:00:00Z", :closed)

      refute Horizon.publication_eligible?(h, dt("2026-06-03T00:00:00Z"))
      assert Horizon.publication_eligible?(h, dt("2026-06-01T12:00:00Z"))
    end

    test "an open policy admits later publication, but only because it says so" do
      h = horizon("2026-06-01T00:00:00Z", "2026-06-02T00:00:00Z", :open)

      assert Horizon.publication_eligible?(h, dt("2026-06-03T00:00:00Z"))
    end

    test "elapsed is evaluated against an injected clock, not wall time" do
      h = horizon("2026-06-01T00:00:00Z", "2026-06-02T00:00:00Z")

      refute Horizon.elapsed?(h, dt("2026-06-01T12:00:00Z"))
      assert Horizon.elapsed?(h, dt("2026-06-02T00:00:00Z"))
    end
  end

  describe "the outcome definition digest" do
    test "is stable for the same definition" do
      a = forecast([0.7, 0.3])
      b = forecast([0.7, 0.3])

      assert a.outcome_definition_digest == b.outcome_definition_digest
    end

    test "changes when the outcome space changes" do
      a = forecast([0.7, 0.3], ["yes", "no"])
      b = forecast([0.7, 0.3], ["yes", "no", "unknown"])

      refute a.outcome_definition_digest == b.outcome_definition_digest
    end

    test "changes when the typed horizon changes" do
      a = forecast([0.7, 0.3])

      {:ok, other} =
        Horizon.from_iso(%{start_at: "2026-06-01T00:00:00Z", end_at: "2026-06-03T00:00:00Z"})

      b = Forecast.new(
        question: "Will it converge?",
        outcomes: ["yes", "no"],
        probabilities: [0.7, 0.3],
        horizon: "48h",
        typed_horizon: other
      )

      refute a.outcome_definition_digest == b.outcome_definition_digest
    end
  end

  describe "canonical scoring, against independently calculated vectors" do
    test "Brier for p=0.7 with the 'yes' outcome realised is 0.09" do
      f = forecast([0.7, 0.3])

      # (0.7 - 1)^2 = 0.09
      assert_in_delta Calibration.score(f, "yes", :brier).value, 0.09, 1.0e-12
    end

    test "Brier for p=0.3 with the 'no' outcome realised is 0.49" do
      f = forecast([0.7, 0.3])

      # (0.3 - 1)^2 = 0.49
      assert_in_delta Calibration.score(f, "no", :brier).value, 0.49, 1.0e-12
    end

    test "log loss for p=0.7 is -ln(0.7)" do
      f = forecast([0.7, 0.3])

      expected = -:math.log(0.7)
      assert_in_delta Calibration.score(f, "yes", :log_loss).value, expected, 1.0e-12
    end

    test "log loss for p=0.3 is -ln(0.3)" do
      f = forecast([0.7, 0.3])

      expected = -:math.log(0.3)
      assert_in_delta Calibration.score(f, "no", :log_loss).value, expected, 1.0e-12
    end

    test "a boundary probability yields an unknown log loss, not infinity" do
      f = forecast([1.0, 0.0])

      result = Calibration.score(f, "yes", :log_loss)
      assert result.value == :unknown
      assert result.sample_size == 0
    end

    test "an unknown probability distribution cannot be scored" do
      f = forecast(:unknown)

      result = Calibration.score(f, "yes", :brier)
      assert result.value == :unknown
      assert result.sample_size == 0
    end

    test "the score records its method and a sample size of one" do
      f = forecast([0.7, 0.3])

      result = Calibration.score(f, "yes", :brier)
      assert result.method == :brier
      assert result.sample_size == 1
    end
  end

  describe "the horizon reaches the registered forecast" do
    test "a registered forecast carries its typed horizon and outcome digest" do
      f = forecast([0.7, 0.3])

      assert %Horizon{} = f.typed_horizon
      assert is_binary(f.outcome_definition_digest)
      assert Horizon.digest(f.typed_horizon) != nil
    end

    test "a forecast without a typed horizon has no digest and is not eligible" do
      f = Forecast.new(question: "Will it converge?", outcomes: ["yes", "no"], probabilities: [0.7, 0.3])

      # A legacy forecast is readable and auditable, but it carries no typed
      # horizon, so it cannot satisfy the temporal eligibility rule.
      assert f.typed_horizon == nil
      assert Contracts.Horizon.event_within?(nil, dt("2026-06-01T12:00:00Z")) == false
    end
  end
end
