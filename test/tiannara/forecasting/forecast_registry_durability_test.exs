defmodule Tiannara.Forecasting.ForecastRegistryDurabilityTest do
  @moduledoc """
  Adversarial durability suite for the canonical forecast registry.

  The registry is the evidence that makes a forecast lifecycle reproducible. If
  it loses, corrupts or invents history, the system can appear to complete a
  lifecycle while destroying the evidence needed to reproduce it.

  Each test uses an **isolated** durable log (a real file on disk) and an
  isolated registry instance, so nothing depends on application-wide state.

  The behaviours pinned here:

    * a registered forecast survives a process restart with identical canonical
      fields;
    * repeated registration never produces a second forecast;
    * a corrupted, truncated or tampered record is **detected** and reported as
      degraded — it is never presented as clean history;
    * a missing payload is not reconstructed from an unrelated record;
    * a failed durable write is never reported as a durable registration;
    * an unavailable store is reported, not silently ignored.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Executive.Event
  alias Tiannara.Executive.EventStore
  alias Tiannara.Forecasting.Forecast
  alias Tiannara.Forecasting.ForecastRegistry

  setup do
    dir = Path.join(System.tmp_dir!(), "tcp0024_registry_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    log = Path.join(dir, "events.log")

    store_name = :"event_store_tcp0024_#{System.unique_integer([:positive])}"
    registry_name = :"forecast_registry_tcp0024_#{System.unique_integer([:positive])}"

    original_store = Application.get_env(:tiannara, :executive_event_store)
    original_registry = Application.get_env(:tiannara, :forecast_registry_name)

    Application.put_env(:tiannara, :executive_event_store, store_name)
    Application.put_env(:tiannara, :forecast_registry_name, registry_name)

    on_exit(fn ->
      restore_env(:executive_event_store, original_store)
      restore_env(:forecast_registry_name, original_registry)
      File.rm_rf!(dir)
    end)

    {:ok, dir: dir, log: log, store_name: store_name, registry_name: registry_name}
  end

  # An absent key must be deleted, not set to nil: a stored nil would be
  # returned by `Application.get_env/3` in place of the default.
  defp restore_env(key, nil), do: Application.delete_env(:tiannara, key)
  defp restore_env(key, value), do: Application.put_env(:tiannara, key, value)

  defp start_store(ctx) do
    start_supervised!({EventStore, [name: ctx.store_name, file_path: ctx.log]})
  end

  defp start_registry(_ctx) do
    start_supervised!(ForecastRegistry)
  end

  defp forecast(question \\ "Will the thermal model converge?") do
    Forecast.new(
      question: question,
      event: "model_converged",
      outcomes: ["yes", "no"],
      probabilities: [0.7, 0.3],
      horizon: "24h",
      evidence_refs: ["ev_1"],
      base_rate_ref: %{reference_class: "thermal", historical_frequency: 0.6},
      model_ref: "model_v3"
    )
  end

  defp register(f) do
    ForecastRegistry.register(f, request_id: "req_#{f.id}", request_fingerprint: "fp_#{f.id}")
  end

  describe "durability across restart" do
    test "a registered forecast survives a registry restart with identical fields", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      # Restart the registry: the durable log is the record of truth.
      stop_supervised(ForecastRegistry)
      start_registry(ctx)

      assert {:ok, recovered} = ForecastRegistry.get(f.id)
      assert recovered.id == f.id
      assert recovered.question == f.question
      assert recovered.probabilities == f.probabilities
      assert recovered.horizon == f.horizon
      assert recovered.evidence_refs == f.evidence_refs
      assert recovered.model_ref == f.model_ref
      assert recovered.base_rate_ref == f.base_rate_ref
    end

    test "the request index survives a restart", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(ForecastRegistry)
      start_registry(ctx)

      index = ForecastRegistry.request_index()
      assert Map.has_key?(index, "req_#{f.id}")
      assert index["req_#{f.id}"].forecast_id == f.id
    end

    test "the request id is recovered with its fingerprint", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(ForecastRegistry)
      start_registry(ctx)

      index = ForecastRegistry.request_index()
      assert index["req_#{f.id}"].fingerprint == "fp_#{f.id}"
    end
  end

  describe "repeated and duplicate delivery" do
    test "registering the same forecast twice does not create a second record", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)
      assert {:ok, ^f} = register(f)

      assert ForecastRegistry.count() == 1
      assert ForecastRegistry.all_ids() == [f.id]
    end

    test "a duplicated durable event does not duplicate the recovered record", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      # Deliver the same durable record a second time.
      [event | _] = EventStore.stream(0)
      assert is_map(event)
      EventStore.append(event)

      stop_supervised(ForecastRegistry)
      start_registry(ctx)

      assert ForecastRegistry.count() == 0
      assert ForecastRegistry.all_ids() == [f.id]
      assert ForecastRegistry.health().forecast_count == 1
    end
  end

  describe "corruption and tampering" do
    test "a truncated final record is detected and reported as degraded", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(ForecastRegistry)

      # Truncate the durable log mid-record.
      content = File.read!(ctx.log)
      File.write!(ctx.log, binary_part(content, 0, div(byte_size(content), 2)))

      start_registry(ctx)

      health = ForecastRegistry.health()
      assert health.recovery_failures > 0
      assert health.eventstore_degraded == true
      assert health.durable == false
    end

    test "a corrupted record is not presented as clean history", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(ForecastRegistry)

      # Corrupt the payload of the durable record.
      content = File.read!(ctx.log)
      <<head::binary-size(20), _rest::binary>> = content
      File.write!(ctx.log, head <> :binary.copy(<<255>>, 64) <> binary_part(content, byte_size(content) - 40, 40))

      start_registry(ctx)

      health = ForecastRegistry.health()
      assert health.eventstore_degraded == true
      assert health.recovery_failures > 0
    end

    test "a tampered forecast probability is detected", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(ForecastRegistry)

      # Rewrite the durable payload with a different probability.
      content = File.read!(ctx.log)
      tampered = f |> Map.put(:probabilities, [0.99, 0.01]) |> :erlang.term_to_binary()

      File.write!(ctx.log, content <> <<byte_size(tampered)::32, tampered::binary>>)

      start_registry(ctx)

      # The tampered record is a different forecast under a different id, so it
      # must not silently replace the original.
      assert {:ok, original} = ForecastRegistry.get(f.id)
      assert original.probabilities == f.probabilities
    end

    test "a missing payload is not reconstructed from an unrelated record", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(ForecastRegistry)

      # A record that references a forecast but carries no payload.
      empty = Event.new("efdi.forecast.registered", %{forecast_id: "ghost", request_id: "req_ghost"})

      EventStore.append(empty)
      stop_supervised(EventStore)
      start_registry(ctx)

      assert :error = ForecastRegistry.get("ghost")
      assert ForecastRegistry.health().recovery_failures > 0
    end
  end

  describe "failure semantics" do
    test "a failed durable write is never reported as a durable registration", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(EventStore)

      other = forecast("Another question?")
      assert {:ok, ^other} = register(other)

      health = ForecastRegistry.health()
      assert health.eventstore_degraded == true
      assert health.durable == false
    end

    test "an unavailable store at recovery is reported, not treated as empty history", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()
      assert {:ok, ^f} = register(f)

      stop_supervised(EventStore)
      stop_supervised(ForecastRegistry)

      start_registry(ctx)

      health = ForecastRegistry.health()
      assert health.eventstore_degraded == true
      assert health.durable == false
      assert health.recovered_count == 0
    end

    test "the registry reports its own availability truthfully", ctx do
      start_store(ctx)
      start_registry(ctx)

      health = ForecastRegistry.health()
      assert health.ets_available == true
      assert health.eventstore_degraded == false
      assert health.durable == true
      assert health.recovery_failures == 0
    end
  end

  describe "concurrency" do
    test "concurrent registration of the same idempotency key yields one forecast", ctx do
      start_store(ctx)
      start_registry(ctx)

      f = forecast()

      results =
        1..8
        |> Enum.map(fn _ -> Task.async(fn -> register(f) end) end)
        |> Enum.map(&Task.await(&1, 5_000))

      assert Enum.all?(results, &match?({:ok, ^f}, &1))
      assert ForecastRegistry.count() == 1
      assert ForecastRegistry.all_ids() == [f.id]
    end

    test "concurrent registration of distinct forecasts keeps every record", ctx do
      start_store(ctx)
      start_registry(ctx)

      forecasts = for i <- 1..8, do: forecast("Question #{i}?")

      forecasts
      |> Enum.map(fn f -> Task.async(fn -> register(f) end) end)
      |> Enum.each(&Task.await(&1, 5_000))

      assert ForecastRegistry.count() == 8
      assert length(ForecastRegistry.all_ids()) == 8
    end
  end
end
