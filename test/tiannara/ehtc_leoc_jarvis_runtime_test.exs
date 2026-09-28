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

  test "LEOC round trip preserves a rank-one state exactly" do
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
    # A rank-one delta projected onto one component is representable without
    # loss, so the seed must report an exact reconstruction rather than claiming
    # an error it does not have.
    assert result.exact == true
    assert result.reconstruction_mse == 0.0

    max_error =
      result.state
      |> Nx.reshape({4, 3})
      |> Nx.subtract(state)
      |> Nx.abs()
      |> Nx.reduce_max()
      |> Nx.to_number()

    assert max_error <= 1.0e-6
  end

  test "LEOC reports a nonzero error when compression discards information" do
    baseline = Nx.broadcast(0.0, {4, 3})

    # Rank-two delta compressed onto one component: information is genuinely
    # discarded, so the seed must not claim an exact reconstruction.
    state =
      Nx.tensor([
        [1.0, 2.0, 0.0],
        [2.0, 4.0, 0.0],
        [3.0, 6.0, 0.0],
        [4.0, 8.0, 0.0]
      ])
      |> Nx.add(Nx.tensor([[0.0, 0.0, 5.0], [0.0, 0.0, 1.0], [0.0, 0.0, 0.0], [0.0, 0.0, 2.0]]))

    ensure_started(Tiannara.LEOC.AnchorRegistry)
    ensure_started(Tiannara.LEOC.BasisRegistry)
    ensure_started(Tiannara.LEOC.SeedVault)

    assert {:ok, _hash} = Tiannara.LEOC.AnchorRegistry.put("world-lossy", baseline)
    assert {:ok, seed} =
             Tiannara.LEOC.Encoder.compress_epoch("world-lossy", 1, state, latent_dimensions: 1)

    assert {:ok, result} = Tiannara.LEOC.Decoder.reconstruct(seed)
    assert result.exact == false
    assert result.reconstruction_mse > 0.0
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
