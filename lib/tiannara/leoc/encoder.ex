defmodule Tiannara.LEOC.Encoder do
  @moduledoc """
  Numeric LEOC encoder.

  The compact seed contains the float32 latent payload and references the
  immutable baseline and decoder basis. It therefore does not claim to contain
  the entire original world state.
  """

  @default_latent_dimensions 1536

  def compress_epoch(world_id, epoch, %Nx.Tensor{} = state, opts \\ []) do
    with {:ok, baseline} <- Tiannara.LEOC.AnchorRegistry.current(world_id),
         {:ok, seed} <- encode(world_id, epoch, state, baseline.tensor, opts),
         :ok <- Tiannara.LEOC.SeedVault.store(seed) do
      {:ok, seed}
    end
  end

  def encode(world_id, epoch, %Nx.Tensor{} = state, %Nx.Tensor{} = baseline, opts \\ []) do
    latent_dimensions = Keyword.get(opts, :latent_dimensions, @default_latent_dimensions)

    with :ok <- validate_shapes(state, baseline),
         {:ok, basis, mean, latent, mse} <- project(state, baseline, latent_dimensions, opts),
         {:ok, basis_hash} <- Tiannara.LEOC.BasisRegistry.put(basis, mean) do
      latent_binary = Nx.to_binary(latent)
      source_hash = Tiannara.LEOC.AnchorRegistry.hash_tensor(state)
      id_material = :erlang.term_to_binary({world_id, epoch, latent_binary})
      id = :crypto.hash(:sha256, id_material)

      {:ok,
       %Tiannara.LEOC.Seed{
         id: Base.encode16(id, case: :lower),
         world_id: world_id,
         epoch: epoch,
         latent_binary: latent_binary,
         latent_shape: Nx.shape(latent),
         baseline_hash: Tiannara.LEOC.AnchorRegistry.hash_tensor(baseline),
         basis_hash: basis_hash,
         source_state_hash: source_hash,
         reconstruction_mse: mse
       }}
    end
  end

  defp project(state, baseline, latent_dimensions, opts) do
    state_matrix = normalize(state)
    baseline_matrix = normalize(baseline)

    if Nx.shape(state_matrix) != Nx.shape(baseline_matrix) do
      {:error, :shape_mismatch}
    else
      delta = Nx.subtract(state_matrix, baseline_matrix)

      with {:ok, basis, meta} <-
             Tiannara.EHTC.compute_principal_eigenvectors(delta, latent_dimensions, opts) do
        mean = meta.mean
        centered = Nx.subtract(delta, mean)

        # The latent payload is persisted as float32, so the reconstruction
        # error must be measured against the float32 latent the decoder will
        # actually read. Measuring it against the higher-precision projection
        # would understate the true decoder error.
        latent =
          Nx.dot(centered, basis)
          |> Nx.as_type({:f, 32})

        reconstructed_delta = Nx.add(Nx.dot(latent, Nx.transpose(basis)), mean)

        mse =
          reconstructed_delta
          |> Nx.subtract(delta)
          |> Nx.pow(2)
          |> Nx.mean()
          |> Nx.to_number()

        {:ok, basis, mean, latent, mse}
      end
    end
  end

  defp validate_shapes(a, b) do
    if Nx.shape(a) == Nx.shape(b), do: :ok, else: {:error, :shape_mismatch}
  end

  defp normalize(%Nx.Tensor{shape: shape} = tensor) do
    dims = Tuple.to_list(shape)
    features = List.last(dims)
    samples = div(Enum.reduce(dims, 1, &*/2), features)
    Nx.reshape(tensor, {samples, features})
  end
end
