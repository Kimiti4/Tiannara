defmodule Tiannara.EhtcLeocJarvisRuntimeTest do
  use ExUnit.Case, async: false

  test "EHTC computes principal components through the real backend" do
    tensor =
      Nx.tensor([
        [1.0, 0.0, 0.0],
        [2.0, 0.0, 0.0],
        [3.0, 0.0, 0.0],
        [4.0, 0.0, 0.0]
      ])

    assert {:ok, basis, meta} =
             Tiannara.Meta.Hardware.EventHorizonTensorCore.dispatch_for_test(tensor, 1)

    assert Nx.shape(basis) == {3, 1}
    assert meta.components == 1
  end

  test "LEOC round trip preserves a rank-one state within error tolerance" do
    baseline = Nx.broadcast(0.0, {4, 3})

    state =
      Nx.tensor([
        [1.0, 2.0, 0.0],
        [2.0, 4.0, 0.0],
        [3.0, 6.0, 0.0],
        [4.0, 8.0, 0.0]
      ])

    ensure_started(Tiannara.LEOC.AnchorRegistry)
    ensure_started(Tiannara.LEOC.BasisRegistry)
    ensure_started(Tiannara.LEOC.SeedVault)

    assert {:ok, _hash} = Tiannara.LEOC.AnchorRegistry.put("world-test", baseline)
    assert {:ok, seed} =
             Tiannara.LEOC.Encoder.compress_epoch("world-test", 1, state, latent_dimensions: 1)

    assert seed.latent_shape == {4, 1}
    assert byte_size(seed.latent_binary) == 16
    assert {:ok, result} = Tiannara.LEOC.Decoder.reconstruct(seed)
    assert result.exact == false
    assert result.reconstruction_mse < 1.0e-5
  end

  test "Jarvis runtime returns a bounded orchestration result" do
    assert {:ok, result} = Tiannara.Agency.JarvisRuntime.execute("design an engineering system", timeout: 1_000)
    assert result.status in [:completed, :degraded, :failed, :rejected]
    assert length(result.domains) <= 6
  end

  defp ensure_started(module) do
    case GenServer.start_link(module, [], name: module) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end
end
